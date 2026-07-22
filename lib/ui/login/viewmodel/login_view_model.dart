import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
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

    final destination = await _resolveDestination();
    if (!ref.mounted) return;
    state = state.copyWith(
      isSigningIn: false,
      destination: LoginDestinationEvent(destination),
    );
  }

  /// 通知が OFF のときだけ誘導画面を挟む。
  ///
  /// 判定に失敗してもホームへ進める。誘導を出すかどうかを決めるだけの問い合わせで、
  /// ここで足を止めるとサインインは済んでいるのにアプリが使えなくなるため
  Future<LoginDestination> _resolveDestination() async {
    try {
      final notificationService = await ref.read(
        fcmNotificationServiceProvider.future,
      );
      return await notificationService.checkPermission()
          ? LoginDestination.home
          : LoginDestination.notificationIntro;
    } catch (e, s) {
      logger.e('checkPermission failed', error: e, stackTrace: s);
      return LoginDestination.home;
    }
  }
}
