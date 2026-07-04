import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

DateTime? computeLastExecutedAt(List<TaskHistory> ascendingHistory) =>
    ascendingHistory.isEmpty ? null : ascendingHistory.last.executedAt;

DateTime? computeScheduledAt({
  required TaskType taskType,
  required List<TaskHistory> ascendingHistory,
  int? scheduleValue,
  ScheduleUnit? scheduleUnit,
}) {
  if (ascendingHistory.isEmpty) return null;
  return switch (taskType) {
    .irregular => null,
    .period => _computePeriodNextAt(ascendingHistory),
    .scheduled => scheduleUnit == null || scheduleValue == null
        ? null
        : scheduleUnit.addTo(ascendingHistory.last.executedAt, scheduleValue),
  };
}

DateTime? _computePeriodNextAt(List<TaskHistory> ascendingHistory) {
  final intervals = intervalDaysForHistory(ascendingHistory);
  if (intervals.isEmpty) return null;
  final avgDays = intervals.average.round();
  return ascendingHistory.last.executedAt.add(Duration(days: avgDays));
}
