import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginUiState build() => const LoginUiState();

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
