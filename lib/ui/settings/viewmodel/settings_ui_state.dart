import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'settings_ui_state.freezed.dart';

enum SettingsDestination { login }

class SettingsDestinationEvent {
  SettingsDestinationEvent(this.type) : id = const Uuid().v4();

  final SettingsDestination type;
  final String id;
}

@freezed
abstract class SettingsUiState with _$SettingsUiState implements BaseUiState {
  const factory SettingsUiState({
    @Default(true) bool isLoading,
    @Default('') String version,
    @Default(NotificationSetting()) NotificationSetting notificationSetting,
    @Default(false) bool isNotificationUpdating,
    @Default(HomeDisplayMode.timeline) HomeDisplayMode displayMode,
    @Default(true) bool progressBarAnimationEnabled,
    @Default(false) bool isGuest,
    @Default(false) bool isSigningOut,
    SettingsDestinationEvent? destination,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _SettingsUiState;
}
