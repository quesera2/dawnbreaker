import 'dart:async';

import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/link_result.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_ui_state.dart';
import 'package:dawnbreaker/ui/login/widgets/login_mode.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

@riverpod
class LoginViewModel extends _$LoginViewModel {
  /// 乗り換え後のユーザーが `currentUserProvider` に反映されるのを待つ上限。
  ///
  /// 待つのは通知の送信先を決めるためだけなので、届かなくてもサインインは成立している
  static const _userUpdateTimeout = Duration(seconds: 5);

  @override
  LoginUiState build({required LoginMode mode}) => const LoginUiState();

  Future<void> onClickStartAsGuest() async {
    if (state.isSigningIn) return;

    state = state.copyWith(isSigningIn: true);
    try {
      await ref.read(userRepositoryProvider).signInAsGuest();
    } catch (e, s) {
      logger.e('signInAsGuest failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSigningIn: false,
        dialogMessage: SignInErrorMessage(primaryHandler: onClickStartAsGuest),
      );
      return;
    }
    if (!ref.mounted) return;

    _updateLastActiveAt();

    final destination = await _resolveDestination();
    if (!ref.mounted) return;
    state = state.copyWith(
      isSigningIn: false,
      destination: LoginDestinationEvent(destination),
    );
  }

  Future<void> onClickSignInWithGoogle() => switch (mode) {
    .initial => _signInWithGoogle(),
    .promotion => _linkWithGoogle(),
  };

  Future<void> _signInWithGoogle() async {
    if (state.isSigningIn) return;

    state = state.copyWith(isSigningIn: true);
    final LoggedIn? user;
    try {
      user = await ref.read(userRepositoryProvider).signInWithGoogle();
    } catch (e, s) {
      logger.e('signInWithGoogle failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSigningIn: false,
        dialogMessage: SignInErrorMessage(
          primaryHandler: onClickSignInWithGoogle,
        ),
      );
      return;
    }
    if (!ref.mounted) return;

    // ユーザーがサインインを中断しただけ。エラーではないのでダイアログは出さない
    if (user == null) {
      state = state.copyWith(isSigningIn: false);
      return;
    }

    _updateLastActiveAt();

    final destination = await _resolveDestination();
    if (!ref.mounted) return;
    state = state.copyWith(
      isSigningIn: false,
      destination: LoginDestinationEvent(destination),
    );
  }

  /// ゲストで作ったタスクを保ったままアカウントを結び付ける
  Future<void> _linkWithGoogle() async {
    if (state.isSigningIn) return;

    state = state.copyWith(isSigningIn: true);
    final LinkResult result;
    try {
      result = await ref.read(userRepositoryProvider).linkWithGoogle();
    } catch (e, s) {
      logger.e('linkWithGoogle failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSigningIn: false,
        dialogMessage: SignInErrorMessage(
          primaryHandler: onClickSignInWithGoogle,
        ),
      );
      return;
    }
    if (!ref.mounted) return;

    switch (result) {
      // ユーザーがサインインを中断しただけ。エラーではないのでダイアログは出さない
      case LinkCancelled():
        state = state.copyWith(isSigningIn: false);
      case LinkSucceeded(:final user):
        await _completeSignIn(user.id);
      // ゲストのタスクを捨てる操作になるため、了承を得るまでサインインしない
      case LinkCredentialInUse(:final credential):
        state = state.copyWith(
          isSigningIn: false,
          dialogMessage: SwitchAccountConfirmMessage(
            primaryHandler: () => unawaited(_switchAccount(credential)),
          ),
        );
    }
  }

  /// 昇格をあきらめて、credential を持っているアカウントへ乗り換える。
  /// ゲストで作ったタスクはここで見捨てる
  Future<void> _switchAccount(AuthCredential credential) async {
    state = state.copyWith(isSigningIn: true);

    // 捨てるアカウント宛の通知がこの端末に届き続けないよう、乗り換える前に送信先から外す
    await _unregisterToken();
    if (!ref.mounted) return;

    final LoggedIn user;
    try {
      user = await ref
          .read(userRepositoryProvider)
          .signInWithLinkedCredential(credential);
    } catch (e, s) {
      logger.e('signInWithLinkedCredential failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSigningIn: false,
        dialogMessage: SignInErrorMessage(
          primaryHandler: () => unawaited(_switchAccount(credential)),
        ),
      );
      return;
    }
    if (!ref.mounted) return;

    await _completeSignIn(user.id);
  }

  /// 昇格・乗り換えのあと始末。
  ///
  /// 通知の誘導は挟まない。ゲストとして使っていた時点で誘導は済んでおり、
  /// ここは設定画面から来た操作なので元の画面へ戻す
  Future<void> _completeSignIn(String userId) async {
    await _registerToken(userId);
    if (!ref.mounted) return;

    _updateLastActiveAt();

    state = state.copyWith(
      isSigningIn: false,
      destination: LoginDestinationEvent(.back),
    );
  }

  /// 通知の送信先をサインイン後のユーザーに付け替える。
  ///
  /// 失敗しても進める。送信先の登録はサインインの成否とは別の話で、ここで足を止めると
  /// サインインは済んでいるのにアプリが使えなくなる
  Future<void> _registerToken(String userId) async {
    try {
      await _waitForCurrentUser(userId);
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      await notificationService.registerToken();
    } catch (e, s) {
      logger.e('registerToken failed', error: e, stackTrace: s);
    }
  }

  /// `currentUserProvider` がサインイン後のユーザーになるまで待つ。
  ///
  /// 通知の送信先を持つリポジトリはこのプロバイダから uid を受け取るが、その更新は
  /// `authStateChanges()` 経由で一拍遅れる。待たずに書くと乗り換え前の uid へ
  /// トークンを書き戻してしまう
  Future<void> _waitForCurrentUser(String userId) {
    bool hasArrived(AppUser user) => user is SignedInUser && user.id == userId;

    if (hasArrived(ref.read(currentUserProvider))) return Future.value();

    final completer = Completer<void>();
    final subscription = ref.listen(currentUserProvider, (_, next) {
      if (hasArrived(next) && !completer.isCompleted) completer.complete();
    });
    return completer.future
        .timeout(_userUpdateTimeout)
        .whenComplete(subscription.close);
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
