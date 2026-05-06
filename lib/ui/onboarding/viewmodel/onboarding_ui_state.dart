import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_ui_state.freezed.dart';

enum OnboardingDestination { home, newTask, pop }

@freezed
abstract class OnboardingUiState
    with _$OnboardingUiState
    implements BaseUiState {
  const OnboardingUiState._();

  const factory OnboardingUiState({
    @Default(false) bool isLoading,
    OnboardingDestination? destination,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _OnboardingUiState;
}
