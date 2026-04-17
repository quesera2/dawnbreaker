import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:flutter/material.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskProgress = task.computeProgress();
    final cardRadius = BorderRadius.circular(12);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: cardRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(theme, colorScheme),
              const SizedBox(height: 8),
              _buildDateRow(context, theme, colorScheme, taskProgress),
              if (taskProgress case DueDate()) ...[
                const SizedBox(height: 10),
                _buildProgressRow(theme, colorScheme, taskProgress),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: task.color.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(task.name, style: theme.textTheme.titleMedium)),
        const SizedBox(width: 4),
        Icon(
          Icons.replay_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          '再登録',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TaskProgress taskProgress,
  ) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        if (task.lastExecutedAt != null)
          Text(
            _formatDate(context, task.lastExecutedAt!),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (taskProgress case DueDate(:final scheduledAt)) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            size: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.event_outlined,
            size: 13,
            color: taskProgress.dueDateColor(colorScheme),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDate(context, scheduledAt),
            style: theme.textTheme.labelMedium?.copyWith(
              color: taskProgress.dueDateColor(colorScheme),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressRow(
    ThemeData theme,
    ColorScheme colorScheme,
    DueDate taskProgress,
  ) {
    final progressColor = taskProgress.progressColor(colorScheme);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taskProgress.progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          taskProgress.isOverdue
              ? '${taskProgress.daysRemaining.abs()}日超過'
              : '残り${taskProgress.daysRemaining}日',
          style: theme.textTheme.labelSmall?.copyWith(
            color: progressColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatShortDate(date);
  }
}

extension _DueDateColors on DueDate {
  Color progressColor(ColorScheme colorScheme) => isOverdue
      ? colorScheme.error
      : progress > 0.5
      ? colorScheme.tertiary
      : colorScheme.primary;

  Color dueDateColor(ColorScheme colorScheme) =>
      isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;
}
