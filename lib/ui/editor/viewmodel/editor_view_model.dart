import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_view_model.g.dart';

@riverpod
class EditorViewModel extends _$EditorViewModel {
  late TaskRepository _repository;

  @override
  EditorUiState build({int? taskId}) {
    _repository = ref.read(taskRepositoryProvider);
    if (taskId != null) {
      unawaited(_loadTask(taskId));
      return const EditorUiState(isLoading: true);
    }
    return const EditorUiState();
  }

  Future<void> _loadTask(int taskId) async {
    try {
      final task = await _repository.findTaskById(taskId);
      if (!ref.mounted) return;
      state = EditorUiState(
        icon: task.icon,
        name: task.name,
        color: task.color,
        taskHistory: task.taskHistory,
        type: task._taskType,
        scheduleValue: task._scheduleValueOrDefault,
        scheduleUnit: task._scheduleUnitOrDefault,
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: TaskLoadErrorMessage(handler: () => _loadTask(taskId)),
      );
    }
  }

  void updateIcon(String icon) => state = state.copyWith(icon: icon);

  void updateName(String name) => state = state.copyWith(name: name);

  void updateType(TaskType type) => state = state.copyWith(type: type);

  void updateColor(TaskColor color) => state = state.copyWith(color: color);

  void updateScheduleValue(int value) =>
      state = state.copyWith(scheduleValue: value);

  void updateScheduleUnit(ScheduleUnit unit) =>
      state = state.copyWith(scheduleUnit: unit);

  Future<void> save() async {
    if (!state.canSave) return;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final id = taskId;
      if (id == null) {
        await _create();
      } else {
        await _update(id);
      }
      if (!ref.mounted) return;
      final message = taskId == null
          ? TaskCreateSuccessSnackMessage(taskName: state.name)
          : TaskUpdateSuccessSnackMessage(taskName: state.name);
      state = state.copyWith(isSaving: false, isSaved: true, snackBarMessage: message);
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSaving: false,
        errorMessage: TaskSaveErrorMessage(handler: save),
      );
    }
  }

  Future<void> _create() async {
    await _repository.addTask(
      taskType: state.type,
      name: state.name,
      icon: state.icon,
      color: state.color,
      scheduleValue: state.scheduleValue,
      scheduleUnit: state.scheduleUnit,
      executedAt: DateTime.now(),
    );
  }

  Future<void> _update(int id) async {
    await _repository.updateTask(
      taskId: id,
      taskType: state.type,
      name: state.name,
      icon: state.icon,
      color: state.color,
      scheduleValue: state.scheduleValue,
      scheduleUnit: state.scheduleUnit,
    );
  }
}

extension _TaskItemEditorExtension on TaskItem {
  TaskType get _taskType => switch (this) {
    IrregularTaskItem() => TaskType.irregular,
    PeriodTaskItem() => TaskType.period,
    ScheduledTaskItem() => TaskType.scheduled,
  };

  int get _scheduleValueOrDefault => switch (this) {
    IrregularTaskItem() => 1,
    PeriodTaskItem() => 1,
    ScheduledTaskItem(:final scheduleValue) => scheduleValue,
  };

  ScheduleUnit get _scheduleUnitOrDefault => switch (this) {
    IrregularTaskItem() => ScheduleUnit.week,
    PeriodTaskItem() => ScheduleUnit.week,
    ScheduledTaskItem(:final scheduleUnit) => scheduleUnit,
  };
}
