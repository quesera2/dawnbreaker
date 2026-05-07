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
    final random = Random();
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    for (final def in dummyTaskDefs) {
      final dates = _generateDates(
        start: oneYearAgo,
        baseIntervalDays: def.baseIntervalDays,
        varianceDays: def.varianceDays,
        until: now,
        random: random,
      );
      if (dates.isEmpty) continue;

      final taskId = await repository.addTask(
        taskType: def.taskType,
        name: def.name,
        icon: def.icon,
        color: def.color,
        executedAt: dates.first,
        scheduleValue: def.scheduleValue,
        scheduleUnit: def.scheduleUnit,
      );

      for (final date in dates.skip(1)) {
        await repository.recordExecution(taskId, executedAt: date);
      }
    }

    if (!ref.mounted) return;
    state = state.copyWith(snackBarMessage: DebugDummyTasksGeneratedMessage());
  }

  List<DateTime> _generateDates({
    required DateTime start,
    required int baseIntervalDays,
    required int varianceDays,
    required DateTime until,
    required Random random,
  }) {
    final dates = <DateTime>[];
    var current = start;
    while (!current.isAfter(until)) {
      dates.add(current);
      final variance = varianceDays > 0
          ? random.nextInt(varianceDays * 2 + 1) - varianceDays
          : 0;
      current = current.add(Duration(days: baseIntervalDays + variance));
    }
    return dates;
  }
}
