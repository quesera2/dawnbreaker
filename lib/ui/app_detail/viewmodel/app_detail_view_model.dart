import 'package:dawnbreaker/data/model/task_history.dart';
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
  AppDetailUiState build({required int taskId}) {
    _repository = ref.read(taskRepositoryProvider);
    _loadTask(taskId);
    return const AppDetailUiState();
  }

  void _loadTask(int taskId) {
    final subscription = _repository
        .watchTaskById(taskId)
        .listen(
          (task) {
            // 削除されたときは無視する
            if (!ref.mounted || task == null) {
              state = state.clearTaskItem();
            } else {
              state = state.updateTaskItem(task);
            }
          },
          onError: (e) {
            if (!ref.mounted) return;
            state = state.copyWith(isLoading: false, shouldPop: true);
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
        executedAt: executedAt,
        comment: comment,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        snackBarMessage: TaskExecutionUpdateSuccess(
          handler: () => updateExecution(
            history,
            executedAt: history.executedAt,
            comment: history.comment,
          ),
        ),
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskUpdateErrorMessage(
          handler: () => updateExecution(
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
        handler: () => deleteTask(),
      ),
    );
  }

  @visibleForTesting
  Future<void> deleteTask() async {
    final task = state.task;
    if (task == null) return;

    try {
      await _repository.deleteTask(task.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        snackBarMessage: TaskDeleteSuccess(
          taskName: task.name,
          handler: () => _repository.restoreTask(task),
        ),
        shouldPop: true,
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskDeleteErrorMessage(handler: deleteTask),
      );
    }
  }
}
