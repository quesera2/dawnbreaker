import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'onboarding_ui_state.freezed.dart';

/// [home] はアカウント削除をやめたときの行き先。消していないので元の場所へ戻す
enum OnboardingDestination { login, pop, home }

class OnboardingDestinationEvent {
  OnboardingDestinationEvent(this.type) : id = const Uuid().v4();

  final OnboardingDestination type;
  final String id;
}

@freezed
abstract class OnboardingUiState
    with _$OnboardingUiState
    implements BaseUiState {
  const OnboardingUiState._();

  const factory OnboardingUiState({
    @Default(false) bool isLoading,
    @Default(false) bool isDeletingAccount,
    OnboardingDestinationEvent? destination,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _OnboardingUiState;
}
