import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_repository_exception.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_ui_state.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_view_model.g.dart';

@riverpod
class OnboardingViewModel extends _$OnboardingViewModel {
  late OnboardingRepository _repository;

  @override
  OnboardingUiState build({required OnboardingMode mode}) {
    _repository = ref.read(onboardingRepositoryProvider);
    return const OnboardingUiState();
  }

  Future<void> onClickDone() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveCompletion();
    } on OnboardingRepositoryException catch (e, s) {
      logger.e('onClickDone failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        dialogMessage: OnboardingSaveErrorMessage(),
      );
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      destination: switch (mode) {
        .initial ||
        .executeAccountDeletion => OnboardingDestinationEvent(.login),
        .fromSettings => OnboardingDestinationEvent(.pop),
      },
    );
  }

  Future<void> onClickSkip() async {
    if (mode == .fromSettings) {
      throw StateError('skip is not available in fromSettings mode');
    }

    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveCompletion();
    } on OnboardingRepositoryException catch (e, s) {
      logger.e('onClickSkip failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        dialogMessage: OnboardingSaveErrorMessage(),
      );
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(destination: OnboardingDestinationEvent(.login));
  }

  /// 設定画面から削除を引き受けて開いたときに、この画面で削除を実行する。
  ///
  /// 送り出した設定画面はサインアウトすると購読が `NoLogin` で走って例外になるため、
  /// ログアウトと同じく、遷移してからこちらで消す
  Future<void> deleteAccount() async {
    if (mode != .executeAccountDeletion) {
      throw StateError(
        'deleteAccount is only available in executeAccountDeletion mode',
      );
    }

    state = state.copyWith(isDeletingAccount: true);

    // 消したアカウント宛の通知がこの端末に届き続けないよう、先に捨てる。
    // Firestore の fcmTokens は users/{uid} ごと消えるため触らない
    await _deleteToken();
    if (!ref.mounted) return;

    final userRepository = ref.read(userRepositoryProvider);
    try {
      await userRepository.deleteAccount();
    } on UserRepositoryException catch (e, s) {
      logger.e('deleteAccount failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      // 消えていないので、やめるならホームへ戻す
      state = state.copyWith(
        isDeletingAccount: false,
        dialogMessage: DeleteAccountErrorMessage(
          primaryHandler: () => unawaited(deleteAccount()),
          secondaryHandler: () => state = state.copyWith(
            destination: OnboardingDestinationEvent(.home),
          ),
        ),
      );
      return;
    }
    if (!ref.mounted) return;

    // 消したあとに開き直したら、初めて使うときと同じチュートリアルから始める。
    // 消えたのはアカウントなので、フラグを消せなくても削除自体は済んでいる
    try {
      await _repository.removeCompletion();
    } on OnboardingRepositoryException catch (e, s) {
      logger.e('removeCompletion failed', error: e, stackTrace: s);
    }
    if (!ref.mounted) return;

    // 消えたアカウントのセッションが残ったままだと、開き直したときにホームへ入ってしまう
    try {
      await userRepository.signOut();
    } catch (e, s) {
      logger.e('signOut after deletion failed', error: e, stackTrace: s);
    }
    if (!ref.mounted) return;

    state = state.copyWith(isDeletingAccount: false);
  }

  /// この端末のトークンを捨てる。失敗しても削除は続ける
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
}
