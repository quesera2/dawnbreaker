import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'display_settings_ui_state.freezed.dart';

@freezed
abstract class DisplaySettingsUiState
    with _$DisplaySettingsUiState
    implements BaseUiState {
  const factory DisplaySettingsUiState({
    @Default(true) bool isLoading,
    HomeDisplayMode? displayMode,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _DisplaySettingsUiState;
}
