import 'package:dawnbreaker/core/util/date_util.dart';

sealed class TaskProgress {
  const TaskProgress();

  factory TaskProgress.from({
    required DateTime? lastExecutedAt,
    required DateTime? scheduledAt,
    required DateTime now,
  }) {
    if (lastExecutedAt == null || scheduledAt == null) return const NoDueDate();

    final lastExecutedDate = lastExecutedAt.truncateTime;
    final scheduledDate = scheduledAt.truncateTime;
    final nowDate = now.truncateTime;

    final totalDays = scheduledDate.difference(lastExecutedDate).inDays;
    final elapsedDays = nowDate.difference(lastExecutedDate).inDays;

    final daysRemaining = scheduledDate.difference(nowDate).inDays;
    final isOverdue = daysRemaining < 0;
    final progress = totalDays > 0
        ? (elapsedDays / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return DueDate(
      scheduledAt: scheduledAt,
      progress: progress,
      daysRemaining: daysRemaining,
      isOverdue: isOverdue,
    );
  }
}

final class NoDueDate extends TaskProgress {
  const NoDueDate();
}

final class DueDate extends TaskProgress {
  const DueDate({
    required this.scheduledAt,
    required this.progress,
    required this.daysRemaining,
    required this.isOverdue,
  });

  final DateTime scheduledAt;

  final double progress;

  /// scheduledAt までの残り日数。超過時は負の値。
  final int daysRemaining;

  final bool isOverdue;

  bool get isToday => daysRemaining == 0;

  bool get isCurrentWeek => daysRemaining <= 7;
}
