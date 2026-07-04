import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_view_model.g.dart';

@riverpod
class EditorViewModel extends _$EditorViewModel {
  late TaskRepository _repository;

  @override
  Future<EditorUiState> build({String? taskId}) async {
    _repository = await ref.read(taskRepositoryProvider.future);
    if (taskId != null) {
      unawaited(_loadTask(taskId));
      return const EditorUiState(isLoading: true);
    }
    return const EditorUiState();
  }

  Future<void> _loadTask(String taskId) async {
    try {
      final task = await _repository.findTaskById(taskId);
      if (!ref.mounted) return;
      state = AsyncData(
        EditorUiState(
          icon: task.icon,
          name: task.name,
          color: task.color,
          type: task.taskType,
          scheduleValue: task.scheduleValueOrDefault,
          scheduleUnit: task.scheduleUnitOrDefault,
        ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('_loadTask failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          isLoading: false,
          dialogMessage: TaskLoadErrorMessage(
            primaryHandler: () => _loadTask(taskId),
          ),
        ),
      );
    }
  }

  void updateIcon(String icon) =>
      state = state.update((s) => s.copyWith(icon: icon));

  void updateName(String name) =>
      state = state.update((s) => s.copyWith(name: name));

  void updateType(TaskType type) =>
      state = state.update((s) => s.copyWith(type: type));

  void updateColor(TaskColor color) =>
      state = state.update((s) => s.copyWith(color: color));

  void updateScheduleValue(int value) =>
      state = state.update((s) => s.copyWith(scheduleValue: value));

  void updateScheduleUnit(ScheduleUnit unit) =>
      state = state.update((s) => s.copyWith(scheduleUnit: unit));

  Future<void> save() async {
    if (!state.requireValue.canSave) return;
    state = state.update(
      (s) => s.copyWith(isSaving: true, dialogMessage: null),
    );
    try {
      final EditorUiState newState;
      if (taskId == null) {
        newState = await _createTask();
      } else {
        newState = await _updateTask(taskId!);
      }
      if (!ref.mounted) return;
      state = AsyncData(newState);
    } on TaskRepositoryException catch (e, s) {
      logger.e('save failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          isSaving: false,
          dialogMessage: TaskSaveErrorMessage(primaryHandler: save),
        ),
      );
    }
  }

  Future<EditorUiState> _createTask() async {
    final s = state.requireValue;
    final newId = await _repository.addTask(
      taskType: s.type,
      name: s.name,
      icon: s.icon,
      color: s.color,
      scheduleValue: s.scheduleValue,
      scheduleUnit: s.scheduleUnit,
    );
    return state.requireValue.copyWith(
      isSaving: false,
      isSaved: true,
      snackBarMessage: TaskCreateSuccess(
        taskName: s.name,
        handler: () => _repository.deleteTask(newId),
      ),
    );
  }

  Future<EditorUiState> _updateTask(String id) async {
    final s = state.requireValue;
    final originalTask = await _repository.findTaskById(id);
    await _repository.updateTask(
      taskId: id,
      taskType: s.type,
      name: s.name,
      icon: s.icon,
      color: s.color,
      scheduleValue: s.scheduleValue,
      scheduleUnit: s.scheduleUnit,
    );
    return state.requireValue.copyWith(
      isSaving: false,
      isSaved: true,
      snackBarMessage: TaskUpdateSuccess(
        taskName: s.name,
        handler: () => _revertTask(originalTask),
      ),
    );
  }

  Future<void> _revertTask(TaskItem original) async {
    await _repository.updateTask(
      taskId: original.id,
      taskType: original.taskType,
      name: original.name,
      icon: original.icon,
      color: original.color,
      scheduleValue: original.scheduleValueOrDefault,
      scheduleUnit: original.scheduleUnitOrDefault,
    );
  }
}
