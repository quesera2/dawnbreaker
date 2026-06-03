import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_ui_state.freezed.dart';

@freezed
abstract class SettingsUiState with _$SettingsUiState implements BaseUiState {
  const factory SettingsUiState({
    @Default(true) bool isLoading,
    @Default('') String version,
    @Default(true) bool notificationEnabled,
    @Default(false) bool isNotificationUpdating,
    @Default(HomeDisplayMode.timeline) HomeDisplayMode displayMode,
    @Default(true) bool progressBarAnimationEnabled,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _SettingsUiState;
}
