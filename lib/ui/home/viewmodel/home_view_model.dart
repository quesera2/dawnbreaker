import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  late TaskRepository _repository;

  @override
  HomeUiState build() {
    _repository = ref.read(taskRepositoryProvider);

    final subscription = _repository.watchAllTasks().listen(
      (tasks) => state = state.copyWith(isLoading: false, tasks: tasks),
    );

    ref.onDispose(subscription.cancel);
    return const HomeUiState(isLoading: true);
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }
}
