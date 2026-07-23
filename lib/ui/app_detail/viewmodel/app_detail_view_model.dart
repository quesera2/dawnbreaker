import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/stream_util.dart' show combineLatest2;
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

// history と hasMore を1つのストリームにまとめて流すためのスナップショット
typedef _HistorySnapshot = ({List<TaskHistory> items, bool hasMore});

@riverpod
class AppDetailViewModel extends _$AppDetailViewModel {
  late TaskRepository _repository;
  late StreamController<_HistorySnapshot> _historyUpdatesController;

  @override
  AppDetailUiState build({required String taskId}) {
    _repository = ref.read(taskRepositoryProvider);
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
      final patched = _patchHistory(state.history, updatedHistory);
      state = state.copyWith(
        snackBarMessage: TaskExecutionUpdateSuccess(
          handler: () => updateExecution(
            task,
            history,
            executedAt: history.executedAt,
            comment: history.comment,
          ),
        ),
      );
      _historyUpdatesController.add((
        items: patched,
        hasMore: state.hasMoreHistory,
      ));
    } on TaskRepositoryException catch (e, s) {
      logger.e('updateExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskUpdateErrorMessage(
          primaryHandler: () => updateExecution(
            task,
            history,
            executedAt: executedAt,
            comment: comment,
          ),
        ),
      );
    }
  }

  void showDeleteTaskDialog() {
    final task = state.task;
    if (task == null) return;
    state = state.copyWith(
      dialogMessage: DeleteTaskConfirmMessage(
        task.name,
        primaryHandler: () => deleteTask(),
      ),
    );
  }

  @visibleForTesting
  Future<void> deleteTask() async {
    final task = state.task;
    if (task == null) return;
    try {
      // deleteTask が返す削除時点の全履歴を、直近件数の制限なしにそのまま undo に使う
      final deletedHistory = await _repository.deleteTask(task.id);
      if (!ref.mounted) return;
      // タスク削除で watchTaskById で前の画面に戻る処理が走る
      state = state.copyWith(
        snackBarMessage: TaskDeleteSuccess(
          taskName: task.name,
          handler: () => _repository.restoreTask([(task, deletedHistory)]),
        ),
      );
    } on TaskRepositoryException catch (e, s) {
      logger.e('deleteTask failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskDeleteErrorMessage(primaryHandler: deleteTask),
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
      final updated = _insertIntoHistory(state.history, history);
      state = state.copyWith(
        snackBarMessage: TaskCompleteSuccess(
          taskName: task.name,
          handler: () =>
              _repository.deleteExecution(history.id, taskId: task.id),
        ),
      );
      _historyUpdatesController.add((
        items: updated,
        hasMore: state.hasMoreHistory,
      ));
    } on TaskRepositoryException catch (e, s) {
      logger.e('recordExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskSaveErrorMessage(
          primaryHandler: () => recordExecution(task, executedAt, comment),
        ),
      );
    }
  }

  Future<void> deleteExecution(TaskItem task, TaskHistory history) async {
    try {
      await _repository.deleteExecution(history.id, taskId: task.id);
      if (!ref.mounted) return;
      final updated = state.history.where((h) => h.id != history.id).toList();
      state = state.copyWith(
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
      _historyUpdatesController.add((
        items: updated,
        hasMore: state.hasMoreHistory,
      ));
    } on TaskRepositoryException catch (e, s) {
      logger.e('deleteExecution failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskExecutionDeleteErrorMessage(
          primaryHandler: () => deleteExecution(task, history),
        ),
      );
    }
  }

  Future<void> loadMoreHistory() async {
    if (!state.hasMoreHistory || state.isLoadingMoreHistory) return;

    final oldestLoaded = state.history.firstOrNull;
    if (oldestLoaded == null) return;

    state = state.copyWith(isLoadingMoreHistory: true);
    try {
      final page = await _repository.fetchTaskHistory(
        taskId,
        cursor: TaskHistoryCursor(
          executedAt: oldestLoaded.executedAt,
          id: oldestLoaded.id,
        ),
      );
      if (!ref.mounted) return;
      final merged = [...page.items.reversed, ...state.history];
      state = state.copyWith(isLoadingMoreHistory: false);
      _historyUpdatesController.add((items: merged, hasMore: page.hasMore));
    } on TaskRepositoryException catch (e, s) {
      logger.e('fetchTaskHistory failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMoreHistory: false);
    }
  }

  // watchTaskById は「タスクが削除された（null）」の検知と、history との
  // combineLatest2 の2つの用途で2回 listen するため、複数購読できるようにしておく
  void _listenForTaskUpdates(String taskId) {
    final taskStream = _repository.watchTaskById(taskId).asBroadcastStream();
    _historyUpdatesController = StreamController<_HistorySnapshot>.broadcast();

    void handleError(Object error, StackTrace stackTrace) {
      logger.e('タスク詳細の取得に失敗', error: error, stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, shouldPop: true);
    }

    // タスクが削除されると null が流れてくるので、history 側を待たずに前の画面に戻る
    final taskDeletedSubscription = taskStream.listen((task) {
      if (task != null) return;
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        task: null,
        history: [],
        historyStats: null,
        daysSinceLastExecution: null,
        averageIntervalDays: null,
        shouldPop: true,
      );
    }, onError: handleError);

    // 初回の履歴を取得する
    unawaited(
      _repository
          .fetchTaskHistory(taskId)
          .then(
            (page) => _historyUpdatesController.add((
              items: page.items.reversed.toList(),
              hasMore: page.hasMore,
            )),
            onError: handleError,
          ),
    );

    final cancelCombine = combineLatest2(
      taskStream.where((task) => task != null).cast<TaskItem>(),
      _historyUpdatesController.stream,
      (TaskItem task, _HistorySnapshot history) {
        if (!ref.mounted) return;
        state = state.updateTaskAndHistory(
          _withRecomputedSchedule(task, history.items),
          history.items,
          hasMoreHistory: history.hasMore,
        );
      },
      onError: handleError,
    );

    ref.onDispose(() {
      unawaited(taskDeletedSubscription.cancel());
      unawaited(cancelCombine());
      unawaited(_historyUpdatesController.close());
    });
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
  // サーバー側（_recalculateScheduleFromHistory）と同じ直近件数で計算し、
  // 再同期後の値と食い違わないようにする
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
