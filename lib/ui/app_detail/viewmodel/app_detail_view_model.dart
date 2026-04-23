import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
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

  Future<void> _loadTask(int taskId) async {
    try {
      final task = await _repository.findTaskById(taskId);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, task: task);
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        shouldPop: true,
        errorMessage: TaskLoadErrorMessage(),
      );
    }
  }

  Future<void> deleteTask() async {
    final task = state.task;
    if (task == null) return;

    try {
      await _repository.deleteTask(task.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        snackBarMessage: TaskDeleteSuccessSnackMessage(
          taskName: task.name,
          handler: () => _repository.restoreTask(task),
        ),
        shouldPop: true,
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        errorMessage: TaskDeleteErrorMessage(handler: deleteTask),
      );
    }
  }
}
