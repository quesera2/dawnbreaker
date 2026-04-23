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
    PeriodTaskItem(:final taskHistory) => _computePeriodNextAt(taskHistory),
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

  static DateTime? _computePeriodNextAt(List<TaskHistory> taskHistory) {
    if (taskHistory.length < 2) return null;
    final intervals = [
      for (var i = 1; i < taskHistory.length; i++)
        taskHistory[i].executedAt
            .difference(taskHistory[i - 1].executedAt)
            .inDays,
    ];
    final avgDays = intervals.reduce((a, b) => a + b) / intervals.length;
    return taskHistory.last.executedAt.add(Duration(days: avgDays.round()));
  }

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
}
