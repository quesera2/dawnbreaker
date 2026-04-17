import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/model/task_color.dart';
import '../../../data/model/task_history.dart';
import '../../../data/model/task_type.dart';

part 'editor_ui_state.freezed.dart';

@freezed
abstract class EditorUiState with _$EditorUiState{
  const factory EditorUiState({
    @Default(false) bool isLoading,
    @Default('📝') String icon,
    @Default('') String name,
    @Default(TaskType.period) TaskType type,
    @Default(TaskColor.none) TaskColor color,
    @Default([]) List<TaskHistory> taskHistory,
  }) = _EditorUiState;
}
