import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
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
    TaskHistory history, {
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
      await _repository.updateExecution(
        history.id,
        taskId: history.taskId,
        executedAt: executedAt,
        comment: comment,
      );
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskExecutionUpdateSuccess(
            handler: () => updateExecution(
              history,
              executedAt: history.executedAt,
              comment: history.comment,
            ),
          ),
        ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('updateExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          dialogMessage: TaskUpdateErrorMessage(
            primaryHandler: () => updateExecution(
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
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskCompleteSuccess(
            taskName: task.name,
            handler: () =>
                _repository.deleteExecution(history.id, taskId: history.taskId),
          ),
        ),
      );
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
      await _repository.deleteExecution(history.id, taskId: history.taskId);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskExecutionDeleteSuccess(
            taskName: task.name,
            executedAt: history.executedAt,
            handler: () => _repository.recordExecution(
              task.id,
              executedAt: history.executedAt,
              comment: history.comment,
            ),
          ),
        ),
      );
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
}
