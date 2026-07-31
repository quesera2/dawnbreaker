import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/sign_in_result.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_ui_state.dart';
import 'package:dawnbreaker/ui/login/widgets/login_param.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginUiState build({required LoginParam param}) => const LoginUiState();

  Future<void> onClickStartAsGuest() async {
    if (state.isSigningIn) return;

    state = state.copyWith(isSigningIn: true);
    try {
      await ref.read(userRepositoryProvider).signInAsGuest();
    } catch (e, s) {
      logger.e('signInAsGuest failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      _showSignInError(onClickStartAsGuest);
      return;
    }
    if (!ref.mounted) return;

    await _completeSignIn();
  }

  /// 初回は素直にサインインし、昇格ではゲストのタスクを保ったまま結び付ける。
  /// どちらもユーザーから見れば Google のボタンを押した 1 つの操作なので、入口は分けない
  Future<void> onClickSignInWithGoogle() async {
    if (state.isSigningIn) return;

    state = state.copyWith(isSigningIn: true);
    try {
      final repository = ref.read(userRepositoryProvider);
      final result = await repository.signInWithGoogle();
      if (!ref.mounted) return;
      switch (result) {
        // ユーザーがサインインを中断しただけ。エラーではないのでダイアログは出さない
        case SignInCancelled():
          state = state.copyWith(isSigningIn: false);
        case SignInSucceeded():
          await _completeSignIn();
        case SignInCredentialInUse(:final credential):
          await _confirmSwitchAccount(credential);
      }
    } catch (e, s) {
      logger.e('signInWithGoogle failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      _showSignInError(onClickSignInWithGoogle);
      return;
    }
  }

  /// ログアウトを仕上げる。設定画面から `executeLogout` で来たときに、
  /// 遷移が終わってから画面側が呼ぶ。
  ///
  /// 設定画面が残っている間にサインアウトすると、残った購読が permission-denied になる
  Future<void> signOut() async {
    if (state.isSigningOut) return;
    state = state.copyWith(isSigningOut: true);

    // サインアウトすると通知の送信先を引けなくなるため、先に捨てる。
    // Firestore の fcmTokens はここでは消さない。無効なトークンは送信側が掃除する
    await _deleteToken();
    if (!ref.mounted) return;

    try {
      await ref.read(userRepositoryProvider).signOut();
    } catch (e, s) {
      logger.e('signOut failed', error: e, stackTrace: s);
    }
    if (!ref.mounted) return;

    state = state.copyWith(
      isSigningOut: false,
      snackBarMessage: SignedOutMessage(),
    );
  }

  /// この端末のトークンを捨てる。失敗してもログアウトは続ける
  Future<void> _deleteToken() async {
    try {
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      await notificationService.deleteToken();
    } catch (e, s) {
      logger.e('deleteToken failed', error: e, stackTrace: s);
    }
  }

  /// 乗り換えるとゲストのタスクは失われる。失うものがあるときだけ了承を求める
  Future<void> _confirmSwitchAccount(AuthCredential credential) async {
    if (!await _hasTasksToLose()) {
      await _switchAccount(credential);
      return;
    }
    if (!ref.mounted) return;

    state = state.copyWith(
      isSigningIn: false,
      dialogMessage: SwitchAccountConfirmMessage(
        primaryHandler: () => unawaited(_switchAccount(credential)),
      ),
    );
  }

  /// 乗り換えで失うタスクがあるか。件数は問わない。
  ///
  /// 確かめられなかったときは「ある」とみなす。黙って消してしまうより、
  /// 消えるものがないときに一度多く確認するほうが害が小さい
  Future<bool> _hasTasksToLose() async {
    try {
      return await ref.read(taskRepositoryProvider).hasAnyTask();
    } catch (e, s) {
      logger.e('hasAnyTask failed', error: e, stackTrace: s);
      return true;
    }
  }

  /// 昇格をあきらめて、credential を持っているアカウントへ乗り換える。
  /// ゲストで作ったタスクはここで見捨てる
  Future<void> _switchAccount(AuthCredential credential) async {
    state = state.copyWith(isSigningIn: true);

    // 捨てるアカウント宛の通知がこの端末に届き続けないよう、乗り換える前に送信先から外す
    await _unregisterToken();
    if (!ref.mounted) return;

    try {
      await ref
          .read(userRepositoryProvider)
          .signInWithLinkedCredential(credential);
    } catch (e, s) {
      logger.e('signInWithLinkedCredential failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      _showSignInError(() => unawaited(_switchAccount(credential)));
      return;
    }
    if (!ref.mounted) return;

    await _completeSignIn();
  }

  /// サインインしたあとの始末。行き先はモードで決まる
  Future<void> _completeSignIn() async {
    _updateLastActiveAt();

    final LoginDestination destination;
    if (param.showGuest) {
      destination = await _resolveDestination();
    } else {
      // 昇格では通知の誘導を挟まない。ゲストとして使っていた時点で誘導は済んでおり、
      // 設定画面から来た操作なので元の画面へ戻す
      await _registerToken();
      destination = .back;
    }
    if (!ref.mounted) return;

    state = state.copyWith(
      isSigningIn: false,
      destination: LoginDestinationEvent(destination),
    );
  }

  /// サインインの失敗を伝えて、その場で再試行できるようにする
  void _showSignInError(VoidCallback retry) {
    state = state.copyWith(
      isSigningIn: false,
      dialogMessage: SignInErrorMessage(primaryHandler: retry),
    );
  }

  /// 通知の送信先をサインイン後のユーザーに付け替える。
  Future<void> _registerToken() async {
    try {
      // 送信先を持つリポジトリは currentUserProvider から uid を受け取る。その更新は
      // authStateChanges() 経由で一拍遅れるため、読み直してから登録する。
      // 読み直しは同期で、サインイン済みのユーザーがそのまま返る
      ref.invalidate(currentUserProvider);
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      await notificationService.registerToken();
    } catch (e, s) {
      logger.e('registerToken failed', error: e, stackTrace: s);
    }
  }

  /// この端末を通知の送信先から外す。失敗しても乗り換えは続ける
  Future<void> _unregisterToken() async {
    try {
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      await notificationService.unregisterToken();
    } catch (e, s) {
      logger.e('unregisterToken failed', error: e, stackTrace: s);
    }
  }

  /// 放置アカウントの回収で使う最終アクティブ日時を進める。
  ///
  /// 画面遷移とは無関係なので待たない。Firestore への書き込みはオフラインだと
  /// 完了しないため、待つとサインインが終わらなくなる
  void _updateLastActiveAt() {
    unawaited(
      ref
          .read(userSettingsRepositoryProvider.future)
          .then((userSettings) => userSettings.updateLastActiveAt())
          .onError((e, s) {
            logger.e('updateLastActiveAt failed', error: e, stackTrace: s);
          }),
    );
  }

  /// 通知が OFF のときだけ誘導画面を挟む。OS の許可が既にあるなら通知を受け取る意思が
  /// あるとみなし、誘導を挟まずに設定を有効にする。
  ///
  /// Android 12 以下は OS に通知の許可を求める仕組みがなく常に許可済みになるため、
  /// 通知が有効になる経路はここだけになる
  ///
  /// 判定に失敗してもホームへ進める。誘導を出すかどうかを決めるだけの問い合わせで、
  /// ここで足を止めるとサインインは済んでいるのにアプリが使えなくなるため
  Future<LoginDestination> _resolveDestination() async {
    try {
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      if (!await notificationService.checkPermission()) {
        return .notificationIntro;
      }
      _enableNotification(notificationService);
      return .home;
    } catch (e, s) {
      logger.e('checkPermission failed', error: e, stackTrace: s);
      return .home;
    }
  }

  /// 画面遷移とは無関係なので待たない。Firestore への書き込みはオフラインだと
  /// 完了しないため、待つとサインインが終わらなくなる
  void _enableNotification(NotificationService notificationService) {
    unawaited(
      _applyNotificationEnabled(notificationService).onError((e, s) {
        logger.e('enable notification failed', error: e, stackTrace: s);
      }),
    );
  }

  Future<void> _applyNotificationEnabled(
    NotificationService notificationService,
  ) async {
    await notificationService.registerToken();
    final userSettings = await ref.read(userSettingsRepositoryProvider.future);
    await userSettings.setNotificationEnabled(true);
  }
}
