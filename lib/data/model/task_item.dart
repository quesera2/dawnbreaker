import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';

@freezed
sealed class TaskItem with _$TaskItem {
  const TaskItem._();

  const factory TaskItem.irregular({
    required int id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required List<TaskHistory> taskHistory,
  }) = IrregularTaskItem;

  const factory TaskItem.period({
    required int id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required List<TaskHistory> taskHistory,
  }) = PeriodTaskItem;

  const factory TaskItem.scheduled({
    required int id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required List<TaskHistory> taskHistory,
  }) = ScheduledTaskItem;

  DateTime? get lastExecutedAt =>
      taskHistory.isEmpty ? null : taskHistory.last.executedAt;

  DateTime? get scheduledAt => switch (this) {
    IrregularTaskItem() => null,
    PeriodTaskItem() => _computePeriodNextAt(
      executionIntervalDays,
      taskHistory,
    ),
    ScheduledTaskItem(
      :final taskHistory,
      :final scheduleValue,
      :final scheduleUnit,
    ) =>
      taskHistory.isEmpty
          ? null
          : scheduleUnit.addTo(taskHistory.last.executedAt, scheduleValue),
  };

  TaskProgress computeProgress([DateTime? now]) => TaskProgress.from(
    lastExecutedAt: lastExecutedAt,
    scheduledAt: scheduledAt,
    now: now ?? DateTime.now(),
  );

  TaskType get taskType => switch (this) {
    IrregularTaskItem() => TaskType.irregular,
    PeriodTaskItem() => TaskType.period,
    ScheduledTaskItem() => TaskType.scheduled,
  };

  int get scheduleValueOrDefault => switch (this) {
    IrregularTaskItem() => 1,
    PeriodTaskItem() => 1,
    ScheduledTaskItem(:final scheduleValue) => scheduleValue,
  };

  ScheduleUnit get scheduleUnitOrDefault => switch (this) {
    IrregularTaskItem() => ScheduleUnit.week,
    PeriodTaskItem() => ScheduleUnit.week,
    ScheduledTaskItem(:final scheduleUnit) => scheduleUnit,
  };

  List<int> get executionIntervalDays {
    if (taskHistory.length < 2) return [];
    return taskHistory.skip(1).indexed.map((item) {
      final (index, current) = item;
      final a = taskHistory[index].executedAt;
      final b = current.executedAt;
      final aDate = DateTime(a.year, a.month, a.day);
      final bDate = DateTime(b.year, b.month, b.day);
      return bDate.difference(aDate).inDays;
    }).toList();
  }

  static DateTime? _computePeriodNextAt(
      List<int> intervals,
      List<TaskHistory> taskHistory,
      ) {
    if (intervals.isEmpty) return null;
    final avgDays = intervals.reduce((a, b) => a + b) / intervals.length;
    return taskHistory.last.executedAt.add(Duration(days: avgDays.round()));
  }
}
