import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
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
  EditorUiState build({String? taskId}) {
    _repository = ref.watch(taskRepositoryProvider);
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
      state = EditorUiState(
        icon: task.icon,
        name: task.name,
        color: task.color,
        type: task.taskType,
        scheduleValue: task.scheduleValueOrDefault,
        scheduleUnit: task.scheduleUnitOrDefault,
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('_loadTask failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        dialogMessage: TaskLoadErrorMessage(
          primaryHandler: () => _loadTask(taskId),
        ),
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
    state = state.copyWith(isSaving: true, dialogMessage: null);
    try {
      final id = taskId;
      if (id == null) {
        await _createTask();
      } else {
        await _updateTask(id);
      }
    } on TaskRepositoryException catch (e, s) {
      logger.e('save failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSaving: false,
        dialogMessage: TaskSaveErrorMessage(primaryHandler: save),
      );
    }
  }

  Future<void> _createTask() async {
    final input = state;
    final newId = await _repository.addTask(
      taskType: input.type,
      name: input.name,
      icon: input.icon,
      color: input.color,
      scheduleValue: input.scheduleValue,
      scheduleUnit: input.scheduleUnit,
    );
    if (!ref.mounted) return;
    state = state.copyWith(
      isSaving: false,
      isSaved: true,
      snackBarMessage: TaskCreateSuccess(
        taskName: input.name,
        handler: () => _repository.deleteTask(newId),
      ),
    );
  }

  Future<void> _updateTask(String id) async {
    final input = state;
    final originalTask = await _repository.findTaskById(id);
    await _repository.updateTask(
      taskId: id,
      taskType: input.type,
      name: input.name,
      icon: input.icon,
      color: input.color,
      scheduleValue: input.scheduleValue,
      scheduleUnit: input.scheduleUnit,
    );
    if (!ref.mounted) return;
    state = state.copyWith(
      isSaving: false,
      isSaved: true,
      snackBarMessage: TaskUpdateSuccess(
        taskName: input.name,
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
