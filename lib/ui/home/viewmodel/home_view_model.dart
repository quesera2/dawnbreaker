import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  late TaskRepository _taskRepository;
  late SettingsRepository _settingsRepository;

  @override
  HomeUiState build() {
    _taskRepository = ref.read(taskRepositoryProvider);
    _settingsRepository = ref.read(settingsRepositoryProvider);
    _initialize();
    return const HomeUiState(isLoading: true);
  }

  Future<void> _initialize() async {
    final taskSub = _taskRepository.allTaskItems().listen((tasks) {
      state = state.copyWith(isLoading: false, tasks: tasks);
    });
    final displayModeSub = _settingsRepository.watchHomeDisplayMode().listen(
      (mode) => state = state.copyWith(displayMode: mode),
    );
    ref.onDispose(taskSub.cancel);
    ref.onDispose(displayModeSub.cancel);
  }

  Future<void> updateDisplayMode(HomeDisplayMode mode) async {
    await _settingsRepository.setHomeDisplayMode(mode);
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
      final history = await _taskRepository.recordExecution(
        task.id,
        executedAt: executedAt,
        comment: comment,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        snackBarMessage: TaskCompleteSuccess(
          taskName: task.name,
          handler: () => _taskRepository.deleteExecution(history.id),
        ),
      );
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        dialogMessage: TaskSaveErrorMessage(
          primaryHandler: () => recordExecution(task, executedAt, comment),
        ),
      );
    }
  }
}
