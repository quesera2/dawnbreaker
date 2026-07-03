import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
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
    _loadTask(taskId);
    return const AppDetailUiState();
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
        final patchedRecent = _patchRecentHistory(
          s.recentHistory,
          updatedHistory,
        );
        final updated = currentTask == null
            ? s
            : s
                  .updateTaskItem(
                    patchedRecent == null
                        ? currentTask
                        : _withRecomputedSchedule(currentTask, patchedRecent),
                  )
                  .updateRecentHistory(patchedRecent ?? s.recentHistory);
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
        final updatedRecent = _insertIntoRecentHistory(
          s.recentHistory,
          history,
        );
        final updated = currentTask == null
            ? s
            : s
                  .updateTaskItem(
                    _withRecomputedSchedule(currentTask, updatedRecent),
                  )
                  .updateRecentHistory(updatedRecent);
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
        final updatedRecent = s.recentHistory
            .where((h) => h.id != history.id)
            .toList();
        final updated = currentTask == null
            ? s
            : s
                  .updateTaskItem(
                    _withRecomputedSchedule(currentTask, updatedRecent),
                  )
                  .updateRecentHistory(updatedRecent);
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

  void _loadTask(String taskId) {
    TaskItem? latestTask;
    List<TaskHistory>? latestHistory;
    var hasTask = false;
    var hasHistory = false;

    void emitIfReady() {
      if (!hasTask || !hasHistory || !ref.mounted) return;
      final task = latestTask;
      final newRecentHistory = latestHistory!;
      if (task == null) {
        state = state.update(
          (s) => s.copyWith(
            isLoading: false,
            task: null,
            recentHistory: [],
            historyStats: null,
            daysSinceLastExecution: null,
            averageIntervalDays: null,
            shouldPop: true,
          ),
        );
        return;
      }
      state = state.update(
        (s) => s
            .copyWith(
              olderHistory: _reconcileOlderHistory(
                previousRecentHistory: s.recentHistory,
                newRecentHistory: newRecentHistory,
                olderHistory: s.olderHistory,
              ),
            )
            .updateTaskItem(task)
            .updateRecentHistory(newRecentHistory),
      );
    }

    void onError(Object e, StackTrace s) {
      logger.e('タスク詳細のストリームでエラーが発生', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.update(
        (s) => s.copyWith(isLoading: false, shouldPop: true),
      );
    }

    final taskSubscription = _repository.watchTaskById(taskId).listen((task) {
      latestTask = task;
      hasTask = true;
      emitIfReady();
    }, onError: onError);
    final historySubscription = _repository.watchTaskHistory(taskId).listen((
      history,
    ) {
      latestHistory = history;
      hasHistory = true;
      emitIfReady();
    }, onError: onError);

    ref.onDispose(() {
      unawaited(taskSubscription.cancel());
      unawaited(historySubscription.cancel());
    });
  }

  // recentHistory は直近件数のみを保持するため、書き込みを契機にストリームが
  // 再emitされると新しいheadからあふれた項目が画面から消えてしまう。
  // 消えた項目を olderHistory 側に退避し、mergedAscendingHistory で拾えるようにする
  List<TaskHistory> _reconcileOlderHistory({
    required List<TaskHistory> previousRecentHistory,
    required List<TaskHistory> newRecentHistory,
    required List<TaskHistory> olderHistory,
  }) {
    final newHeadIds = newRecentHistory.map((h) => h.id).toSet();
    final olderIds = olderHistory.map((h) => h.id).toSet();
    final droppedFromHead = previousRecentHistory.where(
      (h) => !newHeadIds.contains(h.id) && !olderIds.contains(h.id),
    );
    if (droppedFromHead.isEmpty) return olderHistory;
    return [...olderHistory, ...droppedFromHead];
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

  List<TaskHistory> _insertIntoRecentHistory(
    List<TaskHistory> recentHistory,
    TaskHistory history,
  ) {
    if (recentHistory.any((h) => h.id == history.id)) return recentHistory;
    final updated = [...recentHistory, history]
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return updated;
  }

  // recentHistory 内に対象のidがなければ null（変更なし）を返す
  List<TaskHistory>? _patchRecentHistory(
    List<TaskHistory> recentHistory,
    TaskHistory updated,
  ) {
    final index = recentHistory.indexWhere((h) => h.id == updated.id);
    if (index == -1) return null;
    final patched = [...recentHistory]..[index] = updated;
    patched.sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return patched;
  }

  // recentHistory をローカルで書き換えた直後、次の watchTaskHistory の再emitを
  // 待たずに lastExecutedAt/scheduledAt を画面に即時反映するための再計算
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
