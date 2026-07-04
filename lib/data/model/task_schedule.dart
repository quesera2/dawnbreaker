import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

// scheduledAt/lastExecutedAt のキャッシュ計算に使う直近件数の上限。
// Firestore の _updateCache がクエリ段階でこの件数に絞っているのに合わせて、
// restoreTask や画面側での楽観的な再計算も同じ件数に統一する
const scheduleHistoryLimit = 10;

List<TaskHistory> recentHistoryForSchedule(List<TaskHistory> ascendingHistory) {
  if (ascendingHistory.length <= scheduleHistoryLimit) return ascendingHistory;
  return ascendingHistory.sublist(
    ascendingHistory.length - scheduleHistoryLimit,
  );
}

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
