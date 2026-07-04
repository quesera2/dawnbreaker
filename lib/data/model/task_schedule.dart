import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_stats.dart';
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
    .scheduled => computeFixedIntervalScheduledAt(
      lastExecutedAt: ascendingHistory.last.executedAt,
      scheduleValue: scheduleValue,
      scheduleUnit: scheduleUnit,
    ),
  };
}

// ScheduledTaskItem.scheduledAt（履歴を持たず lastExecutedAt だけで計算する）と
// computeScheduledAt の .scheduled ケースの両方から使う、単一の計算箇所
DateTime? computeFixedIntervalScheduledAt({
  required DateTime? lastExecutedAt,
  required int? scheduleValue,
  required ScheduleUnit? scheduleUnit,
}) {
  if (lastExecutedAt == null || scheduleValue == null || scheduleUnit == null) {
    return null;
  }
  return scheduleUnit.addTo(lastExecutedAt, scheduleValue);
}

// 平均間隔日数は TaskHistoryStats（画面表示用の統計）と同じ計算を使う
DateTime? _computePeriodNextAt(List<TaskHistory> ascendingHistory) {
  final averageIntervalDays = TaskHistoryStats.from(
    ascendingHistory,
  ).averageIntervalDays;
  if (averageIntervalDays == null) return null;
  return ascendingHistory.last.executedAt.add(
    Duration(days: averageIntervalDays.round()),
  );
}
