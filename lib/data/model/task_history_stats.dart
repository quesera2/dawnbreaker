import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';

class TaskHistoryStats {
  TaskHistoryStats._({
    required this.historyAndInterval,
    required this.averageIntervalDays,
  });

  factory TaskHistoryStats.from(List<TaskHistory> ascendingHistory) {
    final intervals = intervalDaysForHistory(ascendingHistory);
    return TaskHistoryStats._(
      historyAndInterval: historyAndIntervalPairs(ascendingHistory),
      averageIntervalDays: intervals.isEmpty ? null : intervals.average,
    );
  }

  final List<(TaskHistory, int?)> historyAndInterval;
  final double? averageIntervalDays;
}
