import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_ui_state.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_detail_view_model.g.dart';

@riverpod
class AppDetailViewModel extends _$AppDetailViewModel {
  late TaskRepository _repository;

  @override
  Future<AppDetailUiState> build({required String taskId}) async {
    _repository = await ref.read(taskRepositoryProvider.future);
    _loadTask(taskId);
    return const AppDetailUiState();
  }

  void _loadTask(String taskId) {
    final subscription = _repository
        .watchTaskById(taskId)
        .listen(
          (task) {
            // 削除されたときは前の画面に戻る
            if (!ref.mounted || task == null) {
              state = state.update(
                (s) => s.copyWith(
                  isLoading: false,
                  task: null,
                  historyStats: null,
                  daysSinceLastExecution: null,
                  averageIntervalDays: null,
                  shouldPop: true,
                ),
              );
            } else {
              state = state.update((s) => s.updateTaskItem(task));
            }
          },
          onError: (Object e, StackTrace s) {
            logger.e('watchTaskById stream error', error: e, stackTrace: s);
            if (!ref.mounted) return;
            state = state.update(
              (s) => s.copyWith(isLoading: false, shouldPop: true),
            );
          },
        );
    ref.onDispose(subscription.cancel);
  }

  Future<void> updateExecution(
    TaskItem task,
    TaskHistory history, {
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
      await _repository.updateExecution(
        history.id,
        taskId: task.id,
        executedAt: executedAt,
        comment: comment,
      );
      if (!ref.mounted) return;
      final updatedHistory = history.copyWith(
        executedAt: executedAt,
        comment: comment,
      );
      state = state.update((s) {
        final currentTask = s.task;
        final patchedTask = currentTask == null
            ? null
            : _patchTaskHistory(currentTask, updatedHistory);
        final updated = patchedTask == null ? s : s.updateTaskItem(patchedTask);
        return updated.copyWith(
          olderHistory: _patchOlderHistory(s.olderHistory, updatedHistory),
          snackBarMessage: TaskExecutionUpdateSuccess(
            handler: () => updateExecution(
              task,
              history,
              executedAt: history.executedAt,
              comment: history.comment,
            ),
          ),
        );
      });
    } on TaskRepositoryException catch (e, s) {
      logger.e('updateExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          dialogMessage: TaskUpdateErrorMessage(
            primaryHandler: () => updateExecution(
              task,
              history,
              executedAt: executedAt,
              comment: comment,
            ),
          ),
        ),
      );
    }
  }

  void showDeleteTaskDialog() {
    final task = state.requireValue.task;
    if (task == null) return;
    state = state.update(
      (s) => s.copyWith(
        dialogMessage: DeleteTaskConfirmMessage(
          task.name,
          primaryHandler: () => deleteTask(),
        ),
      ),
    );
  }

  @visibleForTesting
  Future<void> deleteTask() async {
    final task = state.requireValue.task;
    if (task == null) return;
    try {
      await _repository.deleteTask(task.id);
      if (!ref.mounted) return;
      // タスク削除で watchTaskById で前の画面に戻る処理が走る
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskDeleteSuccess(
            taskName: task.name,
            handler: () => _repository.restoreTask(task),
          ),
        ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('deleteTask failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          dialogMessage: TaskDeleteErrorMessage(primaryHandler: deleteTask),
        ),
      );
    }
  }

  Future<void> recordExecution(
    TaskItem task,
    DateTime executedAt,
    String? comment,
  ) async {
    try {
      final history = await _repository.recordExecution(
        task.id,
        executedAt: executedAt,
        comment: comment,
      );
      if (!ref.mounted) return;
      state = state.update((s) {
        final currentTask = s.task;
        final updated = currentTask == null
            ? s
            : s.updateTaskItem(_insertIntoTaskHistory(currentTask, history));
        return updated.copyWith(
          snackBarMessage: TaskCompleteSuccess(
            taskName: task.name,
            handler: () =>
                _repository.deleteExecution(history.id, taskId: task.id),
          ),
        );
      });
    } on TaskRepositoryException catch (e, s) {
      logger.e('recordExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          dialogMessage: TaskSaveErrorMessage(
            primaryHandler: () => recordExecution(task, executedAt, comment),
          ),
        ),
      );
    }
  }

  Future<void> deleteExecution(TaskItem task, TaskHistory history) async {
    try {
      await _repository.deleteExecution(history.id, taskId: task.id);
      if (!ref.mounted) return;
      state = state.update((s) {
        final currentTask = s.task;
        final removedFromTask = currentTask == null
            ? null
            : currentTask.copyWith(
                taskHistory: currentTask.taskHistory
                    .where((h) => h.id != history.id)
                    .toList(),
              );
        final updated = removedFromTask == null
            ? s
            : s.updateTaskItem(removedFromTask);
        return updated.copyWith(
          olderHistory: s.olderHistory
              .where((h) => h.id != history.id)
              .toList(),
          snackBarMessage: TaskExecutionDeleteSuccess(
            taskName: task.name,
            executedAt: history.executedAt,
            handler: () => _repository.recordExecution(
              task.id,
              executedAt: history.executedAt,
              comment: history.comment,
            ),
          ),
        );
      });
    } on TaskRepositoryException catch (e, s) {
      logger.e('deleteExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          dialogMessage: TaskExecutionDeleteErrorMessage(
            primaryHandler: () => deleteExecution(task, history),
          ),
        ),
      );
    }
  }

  Future<void> loadMoreHistory() async {
    final current = state.value;
    final task = current?.task;
    if (current == null || task == null) return;
    if (!current.hasMoreHistory || current.isLoadingMoreHistory) return;

    final oldestLoaded = current.mergedAscendingHistory.firstOrNull;
    if (oldestLoaded == null) return;

    state = state.update((s) => s.copyWith(isLoadingMoreHistory: true));
    try {
      final page = await _repository.fetchOlderHistory(
        task.id,
        cursor: TaskHistoryCursor(
          executedAt: oldestLoaded.executedAt,
          id: oldestLoaded.id,
        ),
      );
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          olderHistory: [...page.items.reversed, ...s.olderHistory],
          hasMoreHistory: page.hasMore,
          isLoadingMoreHistory: false,
        ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('fetchOlderHistory failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update((s) => s.copyWith(isLoadingMoreHistory: false));
    }
  }

  List<TaskHistory> _patchOlderHistory(
    List<TaskHistory> olderHistory,
    TaskHistory updated,
  ) {
    final index = olderHistory.indexWhere((h) => h.id == updated.id);
    if (index == -1) return olderHistory;
    final patched = [...olderHistory]..[index] = updated;
    patched.sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return patched;
  }

  TaskItem _insertIntoTaskHistory(TaskItem task, TaskHistory history) {
    if (task.taskHistory.any((h) => h.id == history.id)) return task;
    final updated = [...task.taskHistory, history]
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return task.copyWith(taskHistory: updated);
  }

  // task.taskHistory（head）内に対象のidがなければ null（変更なし）を返す
  TaskItem? _patchTaskHistory(TaskItem task, TaskHistory updated) {
    final index = task.taskHistory.indexWhere((h) => h.id == updated.id);
    if (index == -1) return null;
    final patched = [...task.taskHistory]..[index] = updated;
    patched.sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return task.copyWith(taskHistory: patched);
  }
}
