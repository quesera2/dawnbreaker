import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';

@freezed
sealed class TaskItem with _$TaskItem {
  const TaskItem._();

  const factory TaskItem.irregular({
    required String id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required DateTime? lastExecutedAt,
  }) = IrregularTaskItem;

  const factory TaskItem.period({
    required String id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required DateTime? lastExecutedAt,
    required DateTime? cachedScheduledAt,
  }) = PeriodTaskItem;

  const factory TaskItem.scheduled({
    required String id,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required DateTime? lastExecutedAt,
  }) = ScheduledTaskItem;

  // PeriodTaskItem は複数実行の間隔平均が必要で taskHistory 全体がないと
  // 計算できないため、リポジトリ側で計算済みの値を cachedScheduledAt として保持する
  DateTime? get scheduledAt => switch (this) {
    IrregularTaskItem() => null,
    PeriodTaskItem(:final cachedScheduledAt) => cachedScheduledAt,
    ScheduledTaskItem(
      :final lastExecutedAt,
      :final scheduleValue,
      :final scheduleUnit,
    ) =>
      lastExecutedAt == null
          ? null
          : scheduleUnit.addTo(lastExecutedAt, scheduleValue),
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
}
