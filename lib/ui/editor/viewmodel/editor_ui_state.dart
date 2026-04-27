import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_ui_state.freezed.dart';

@freezed
abstract class EditorUiState with _$EditorUiState implements BaseUiState {
  const EditorUiState._();

  const factory EditorUiState({
    @Default(false) bool isLoading,
    @Default('📝') String icon,
    @Default('') String name,
    @Default(TaskType.period) TaskType type,
    @Default(TaskColor.none) TaskColor color,
    @Default(1) int scheduleValue,
    @Default(ScheduleUnit.week) ScheduleUnit scheduleUnit,
    @Default([]) List<TaskHistory> taskHistory,
    ErrorMessage? errorMessage,
    SnackBarMessage? snackBarMessage,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _EditorUiState;

  bool get canSave => name.trim().isNotEmpty;
}
