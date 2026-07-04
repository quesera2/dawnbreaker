import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/core/util/stream_util.dart' show combineLatest2;
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
    _listenForTaskUpdates(taskId);
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

  // watchTaskById（ライブ更新）と fetchTaskHistory（初期表示用の1回きりの取得）を
  // combineLatest2 でまとめて1つの更新経路にする。build() は初期状態を同期的に返し
  // ここでの更新はすべて state.update 経由になるため、「build() 完了前に2件目の
  // イベントが来て state がまだ値を持たない」という競合が起きない。
  // 最初の1回だけ history も含めて反映し、以降は task 側の更新のみ反映する
  void _listenForTaskUpdates(String taskId) {
    var isFirstEmission = true;
    final cancel = combineLatest2(
      _repository.watchTaskById(taskId),
      _repository.fetchTaskHistory(taskId).asStream(),
      (TaskItem? task, TaskHistoryPage historyPage) {
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
        if (isFirstEmission) {
          isFirstEmission = false;
          state = state.update(
            (s) => s
                .updateTaskItem(task)
                .updateHistory(historyPage.items.reversed.toList())
                .copyWith(hasMoreHistory: historyPage.hasMore),
          );
          return;
        }
        state = state.update((s) => s.updateTaskItem(task));
        // task 側の更新だけでは実行履歴の変更（他端末からの記録・編集・削除）が
        // 画面に反映されないため、直近の履歴を Future ベースで取り直して補う
        unawaited(_refreshRecentHistory(taskId));
      },
      onError: (e, s) {
        logger.e('タスク詳細の取得に失敗', error: e, stackTrace: s);
        if (!ref.mounted) return;
        state = state.update(
          (s) => s.copyWith(isLoading: false, shouldPop: true),
        );
      },
    );
    ref.onDispose(() => unawaited(cancel()));
  }

  // タスクが外部で更新されたたびに直近ページを取り直し、ページング済みの
  // 古い履歴はそのまま残しつつ直近ウィンドウ内の追加・編集・削除だけ反映する
  Future<void> _refreshRecentHistory(String taskId) async {
    try {
      final page = await _repository.fetchTaskHistory(taskId);
      if (!ref.mounted) return;
      state = state.update((s) {
        if (page.items.isEmpty) return s.updateHistory(const []);
        final oldestFresh = page.items
            .map((h) => h.executedAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final keptOlder = s.history
            .where((h) => h.executedAt.isBefore(oldestFresh))
            .toList();
        final merged = [...keptOlder, ...page.items.reversed]
          ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
        return s
            .updateHistory(merged)
            .copyWith(
              hasMoreHistory: keptOlder.isEmpty
                  ? page.hasMore
                  : s.hasMoreHistory,
            );
      });
    } catch (e, s) {
      logger.e('タスク詳細の履歴再取得に失敗', error: e, stackTrace: s);
    }
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
  // lastExecutedAt/scheduledAt を画面に即時反映するための再計算。
  // サーバー側（_updateCache）と同じ直近件数で計算し、再同期後の値と食い違わないようにする
  TaskItem _withRecomputedSchedule(
    TaskItem task,
    List<TaskHistory> ascendingHistory,
  ) {
    final recentHistory = recentHistoryForSchedule(ascendingHistory);
    final lastExecutedAt = computeLastExecutedAt(recentHistory);
    return switch (task) {
      IrregularTaskItem() => task.copyWith(lastExecutedAt: lastExecutedAt),
      ScheduledTaskItem() => task.copyWith(lastExecutedAt: lastExecutedAt),
      PeriodTaskItem() => task.copyWith(
        lastExecutedAt: lastExecutedAt,
        cachedScheduledAt: computeScheduledAt(
          taskType: task.taskType,
          ascendingHistory: recentHistory,
        ),
      ),
    };
  }
}
