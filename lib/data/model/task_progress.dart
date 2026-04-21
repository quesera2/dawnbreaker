sealed class TaskProgress {
  const TaskProgress();

  factory TaskProgress.from({
    required DateTime? lastExecutedAt,
    required DateTime? scheduledAt,
    required DateTime now,
  }) {
    if (lastExecutedAt == null || scheduledAt == null) return const NoDueDate();

    final totalDays = scheduledAt.difference(lastExecutedAt).inDays;
    final elapsedDays = now.difference(lastExecutedAt).inDays;
    final daysRemaining = scheduledAt.difference(now).inDays;
    final isOverdue = now.isAfter(scheduledAt);
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
