import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
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
      state = switch (task) {
        PeriodTaskItem() => EditorUiState(
          icon: task.icon,
          name: task.name,
          type: TaskType.period,
          color: task.color,
          taskHistory: task.taskHistory,
        ),
        ScheduledTaskItem() => EditorUiState(
          icon: task.icon,
          name: task.name,
          type: TaskType.scheduled,
          color: task.color,
          scheduleValue: task.scheduleValue,
          scheduleUnit: task.scheduleUnit,
          taskHistory: task.taskHistory,
        ),
      };
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = taskId;
      if (id == null) {
        await _create();
      } else {
        await _update(id);
      }
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, isSaved: true);
    } on TaskRepositoryException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _create() async {
    final now = DateTime.now();
    switch (state.type) {
      case TaskType.period:
        await _repository.addPeriodTask(
          name: state.name,
          icon: state.icon,
          color: state.color,
          executedAt: now,
        );
      case TaskType.scheduled:
        await _repository.addScheduledTask(
          name: state.name,
          icon: state.icon,
          color: state.color,
          scheduleValue: state.scheduleValue,
          scheduleUnit: state.scheduleUnit,
          executedAt: now,
        );
    }
  }

  Future<void> _update(int id) async {
    final isScheduled = state.type == TaskType.scheduled;
    await _repository.updateTask(
      taskId: id,
      taskType: state.type,
      name: state.name,
      icon: state.icon,
      color: state.color,
      scheduleValue: isScheduled ? state.scheduleValue : null,
      scheduleUnit: isScheduled ? state.scheduleUnit : null,
    );
  }
}