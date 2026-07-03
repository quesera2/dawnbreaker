import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class TaskHistoryStats {
  TaskHistoryStats._({
    required this.historyAndInterval,
    required this.averageIntervalDays,
  });

  factory TaskHistoryStats.from(TaskItem task) {
    final intervals = task.executionIntervalDays;
    return TaskHistoryStats._(
      historyAndInterval: historyAndIntervalPairs(task.taskHistory),
      averageIntervalDays: intervals.isEmpty ? null : intervals.average,
    );
  }

  final List<(TaskHistory, int?)> historyAndInterval;
  final double? averageIntervalDays;
}
