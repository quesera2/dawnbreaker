import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  late TaskRepository _repository;

  @override
  HomeUiState build() {
    _repository = ref.read(taskRepositoryProvider);
    _initialize();
    return const HomeUiState(isLoading: true);
  }

  Future<void> _initialize() async {
    final subscription = _repository.allTaskItems().listen((tasks) {
      state = state.copyWith(isLoading: false, tasks: tasks);
    });
    ref.onDispose(subscription.cancel);
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }

  void updateFilter(HomeFilter filter) {
    if (filter == state.selectedFilter) return;
    state = state.copyWith(selectedFilter: filter);
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
      state = state.copyWith(
        snackBarMessage: TaskCompleteSuccessSnackMessage(
          taskName: task.name,
          handler: () => _repository.deleteExecution(history.id),
        ),
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: TaskSaveErrorMessage());
    }
  }
}
