import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_ui_state.freezed.dart';

@freezed
abstract class OnboardingUiState
    with _$OnboardingUiState
    implements BaseUiState {
  const OnboardingUiState._();

  const factory OnboardingUiState({
    @Default(false) bool isCompleting,
    ErrorMessage? errorMessage,
    SnackBarMessage? snackBarMessage,
  }) = _OnboardingUiState;
}
