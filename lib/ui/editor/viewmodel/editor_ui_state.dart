import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_ui_state.freezed.dart';

@freezed
abstract class EditorUiState with _$EditorUiState {
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
    String? errorMessage,
    @Default(false) bool isSaved,
  }) = _EditorUiState;

  bool get canSave => name.trim().isNotEmpty;
}
