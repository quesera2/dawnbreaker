import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_label_ui_state.freezed.dart';

enum ColorLabelMode {
  edit,
  sort;

  ColorLabelMode get toggled => switch (this) {
    .edit => .sort,
    .sort => .edit,
  };
}

@freezed
abstract class ColorLabelUiState
    with _$ColorLabelUiState
    implements BaseUiState {
  const factory ColorLabelUiState({
    @Default(true) bool isLoading,
    @Default([]) List<ColorSetting> settings,
    @Default(ColorLabelMode.edit) ColorLabelMode mode,
    DialogMessage? dialogMessage,
    SnackBarMessage? snackBarMessage,
  }) = _ColorLabelUiState;
}
