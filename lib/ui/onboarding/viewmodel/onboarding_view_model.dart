import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
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
    } on OnboardingRepositoryException {
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
        .initial => OnboardingDestinationEvent(.newTask),
        .fromSettings => OnboardingDestinationEvent(.pop),
      },
    );
  }

  Future<void> onRequestNotification() async {
    final notificationService = await ref.read(
      notificationServiceProvider.future,
    );
    final isGranted = await notificationService.requestPermission();
    if (isGranted) {
      await _repository.enableNotificationSettings();
    }
    if (!ref.mounted) return;
    state = state.copyWith(destination: OnboardingDestinationEvent(.next));
  }

  Future<void> onClickSkip() async {
    if (mode == .fromSettings) {
      throw StateError('skip is not available in fromSettings mode');
    }

    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveCompletion();
    } on OnboardingRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        dialogMessage: OnboardingSaveErrorMessage(),
      );
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(destination: OnboardingDestinationEvent(.home));
  }
}
