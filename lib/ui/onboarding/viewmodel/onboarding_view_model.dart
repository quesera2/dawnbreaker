import 'package:dawnbreaker/core/logger/app_logger.dart';
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
        .initial => OnboardingDestinationEvent(.login),
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
}
