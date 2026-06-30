import 'dart:async';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/util/async_value_extension.dart';
import 'package:dawnbreaker/core/util/stream_util.dart' show combineLatest4;
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_provider.dart';
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
  Future<HomeUiState> build() async {
    _taskRepository = await ref.read(taskRepositoryProvider.future);
    _settingsRepository = ref.read(settingsRepositoryProvider);
    _initialize();
    return const HomeUiState(isLoading: true);
  }

  void _initialize() {
    final disposable = combineLatest4(
      _taskRepository.allTaskItems(),
      _settingsRepository.watchHomeDisplayMode(),
      _settingsRepository.watchColorSettings(),
      _settingsRepository.watchProgressBarAnimationEnabled(),
      (
        List<TaskItem> tasks,
        HomeDisplayMode mode,
        List<ColorSetting> colorSettings,
        bool progressBarAnimationEnabled,
      ) => state = state.update(
        (s) => s.copyWith(
          isLoading: false,
          tasks: tasks,
          displayMode: mode,
          colorSettings: colorSettings,
          progressBarAnimationEnabled: progressBarAnimationEnabled,
        ),
      ),
    );
    ref.onDispose(() => unawaited(disposable()));
  }

  Future<void> updateDisplayMode(HomeDisplayMode mode) async {
    await _settingsRepository.setHomeDisplayMode(mode);
  }

  void updateSearchQuery(String query) {
    if (query == state.requireValue.searchQuery) return;
    state = state.update((s) => s.copyWith(searchQuery: query));
  }

  void updateFilter(HomeFilter filter) {
    if (filter == state.requireValue.selectedFilter) return;
    state = state.update((s) => s.copyWith(selectedFilter: filter));
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
      state = state.update(
        (s) => s.copyWith(
          snackBarMessage: TaskCompleteSuccess(
            taskName: task.name,
            handler: () => _taskRepository.deleteExecution(
              history.id,
              taskId: history.taskId,
            ),
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
}
