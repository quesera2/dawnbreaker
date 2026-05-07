import 'dart:math';

import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/dummy_tasks.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsUiState build() {
    _initialize();
    return const SettingsUiState();
  }

  Future<void> _initialize() async {
    final info = await PackageInfo.fromPlatform();
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false, version: info.version);
  }

  Future<void> generateDummyTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteAllTasks();
    for (final task in buildDummyTasks(now: DateTime.now(), random: Random())) {
      await repository.restoreTask(task);
    }
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: DebugDummyTasksGeneratedMessage());
  }

  Future<void> deleteAllTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteAllTasks();
    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: AllTasksDeletedMessage());
  }
}
