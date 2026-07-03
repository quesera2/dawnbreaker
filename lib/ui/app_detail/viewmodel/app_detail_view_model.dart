import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_history_page.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_schedule.dart';
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

    final firstTask = Completer<TaskItem?>();
    _listenForTaskUpdates(taskId, firstTask);

    final TaskItem? initialTask;
    final TaskHistoryPage initialPage;
    try {
      (initialTask, initialPage) = await (
        firstTask.future,
        _repository.fetchTaskHistory(taskId),
      ).wait;
    } catch (e, s) {
      logger.e('タスク詳細の初期読み込みに失敗', error: e, stackTrace: s);
      return const AppDetailUiState(isLoading: false, shouldPop: true);
    }

    if (initialTask == null) {
      return const AppDetailUiState(isLoading: false, shouldPop: true);
    }
    return const AppDetailUiState()
        .updateTaskItem(initialTask)
        .updateHistory(initialPage.items.reversed.toList())
        .copyWith(hasMoreHistory: initialPage.hasMore);
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
        final patched = _patchHistory(s.history, updatedHistory);
        final updated = currentTask == null
            ? s
            : s
                  .updateTaskItem(_withRecomputedSchedule(currentTask, patched))
                  .updateHistory(patched);
        return updated.copyWith(
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
      // deleteTask が返す削除時点の全履歴を、直近件数の制限なしにそのまま undo に使う
      final deletedHistory = await _repository.deleteTask(task.id);
      if (!ref.mounted) return;
      // タスク削除で watchTaskById で前の画面に戻る処理が走る
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskDeleteSuccess(
            taskName: task.name,
            handler: () => _repository.restoreTask(task, deletedHistory),
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
        final updated = _insertIntoHistory(s.history, history);
        final updatedState = currentTask == null
            ? s
            : s
                  .updateTaskItem(_withRecomputedSchedule(currentTask, updated))
                  .updateHistory(updated);
        return updatedState.copyWith(
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
        final updated = s.history.where((h) => h.id != history.id).toList();
        final updatedState = currentTask == null
            ? s
            : s
                  .updateTaskItem(_withRecomputedSchedule(currentTask, updated))
                  .updateHistory(updated);
        return updatedState.copyWith(
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
    if (current == null) return;
    if (!current.hasMoreHistory || current.isLoadingMoreHistory) return;

    final oldestLoaded = current.history.firstOrNull;
    if (oldestLoaded == null) return;

    state = state.update((s) => s.copyWith(isLoadingMoreHistory: true));
    try {
      final page = await _repository.fetchTaskHistory(
        taskId,
        cursor: TaskHistoryCursor(
          executedAt: oldestLoaded.executedAt,
          id: oldestLoaded.id,
        ),
      );
      if (!ref.mounted) return;
      state = state.update(
        (s) => s
            .updateHistory([...page.items.reversed, ...s.history])
            .copyWith(
              hasMoreHistory: page.hasMore,
              isLoadingMoreHistory: false,
            ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('fetchTaskHistory failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update((s) => s.copyWith(isLoadingMoreHistory: false));
    }
  }

  // watchTaskById は1つの購読だけを維持する。最初の1件は build() が待つ初期値として
  // firstTask 経由で渡し、2件目以降はここで直接 state を更新する
  void _listenForTaskUpdates(String taskId, Completer<TaskItem?> firstTask) {
    final subscription = _repository
        .watchTaskById(taskId)
        .listen(
          (task) {
            if (!firstTask.isCompleted) {
              firstTask.complete(task);
              return;
            }
            if (!ref.mounted) return;
            if (task == null) {
              state = state.update(
                (s) => s.copyWith(
                  isLoading: false,
                  task: null,
                  history: [],
                  historyStats: null,
                  daysSinceLastExecution: null,
                  averageIntervalDays: null,
                  shouldPop: true,
                ),
              );
              return;
            }
            state = state.update((s) => s.updateTaskItem(task));
          },
          onError: (Object e, StackTrace s) {
            logger.e('watchTaskById stream error', error: e, stackTrace: s);
            if (!firstTask.isCompleted) {
              firstTask.completeError(e, s);
              return;
            }
            if (!ref.mounted) return;
            state = state.update(
              (s) => s.copyWith(isLoading: false, shouldPop: true),
            );
          },
        );
    ref.onDispose(subscription.cancel);
  }

  List<TaskHistory> _insertIntoHistory(
    List<TaskHistory> history,
    TaskHistory inserted,
  ) {
    if (history.any((h) => h.id == inserted.id)) return history;
    final updated = [...history, inserted]
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return updated;
  }

  List<TaskHistory> _patchHistory(
    List<TaskHistory> history,
    TaskHistory updated,
  ) {
    final index = history.indexWhere((h) => h.id == updated.id);
    if (index == -1) return history;
    final patched = [...history]..[index] = updated;
    patched.sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return patched;
  }

  // history をローカルで書き換えた直後、サーバーとの再同期を待たずに
  // lastExecutedAt/scheduledAt を画面に即時反映するための再計算
  TaskItem _withRecomputedSchedule(
    TaskItem task,
    List<TaskHistory> ascendingHistory,
  ) {
    final lastExecutedAt = computeLastExecutedAt(ascendingHistory);
    return switch (task) {
      IrregularTaskItem() => task.copyWith(lastExecutedAt: lastExecutedAt),
      ScheduledTaskItem() => task.copyWith(lastExecutedAt: lastExecutedAt),
      PeriodTaskItem() => task.copyWith(
        lastExecutedAt: lastExecutedAt,
        cachedScheduledAt: computeScheduledAt(
          taskType: task.taskType,
          ascendingHistory: ascendingHistory,
        ),
      ),
    };
  }
}
