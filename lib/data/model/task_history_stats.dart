import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class TaskHistoryStats {
  TaskHistoryStats._({
    required this.historyAndInterval,
    required this.averageIntervalDays,
  });

  factory TaskHistoryStats.from(TaskItem task) {
    final reversedHistory = task.taskHistory.reversed;
    final reversedIntervals = task.executionIntervalDays.reversed;
    return TaskHistoryStats._(
      historyAndInterval: reversedHistory
          .mapIndexed(
            (index, history) =>
                (history, reversedIntervals.elementAtOrNull(index)),
          )
          .toList(),
      averageIntervalDays: reversedIntervals.isEmpty
          ? null
          : reversedIntervals.average,
    );
  }

  final List<(TaskHistory, int?)> historyAndInterval;
  final double? averageIntervalDays;
}
