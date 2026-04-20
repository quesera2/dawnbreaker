import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({super.key, required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskProgress = task.computeProgress();
    final cardRadius = BorderRadius.circular(12);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(width: 16, color: task.color.color),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _EmojiCircle(icon: task.icon, colorScheme: colorScheme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleRow(context, theme, colorScheme),
                            if (taskProgress is DueDate) ...[
                              const SizedBox(height: 4),
                              _buildDateInfo(
                                context,
                                theme,
                                colorScheme,
                                taskProgress,
                              ),
                              const SizedBox(height: 8),
                              _buildProgressBar(colorScheme, taskProgress),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(child: Text(task.name, style: theme.textTheme.titleMedium)),
        const SizedBox(width: 4),
        Icon(
          Icons.replay_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          context.l10n.homeReRegister,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    DueDate taskProgress,
  ) {
    final date = taskProgress.scheduledAt;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMd(locale).format(date);
    final remainStr = taskProgress.isOverdue
        ? context.l10n.homeDaysOverdue(taskProgress.daysRemaining.abs())
        : context.l10n.homeDaysRemaining(taskProgress.daysRemaining);
    final color = taskProgress.isOverdue
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.event_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$dateStr（$remainStr）',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme, DueDate taskProgress) {
    final progressColor = taskProgress.isOverdue
        ? colorScheme.error
        : taskProgress.progress > 0.5
        ? colorScheme.tertiary
        : colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: taskProgress.progress,
        minHeight: 6,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
      ),
    );
  }
}


class _EmojiCircle extends StatelessWidget {
  const _EmojiCircle({required this.icon, required this.colorScheme});

  final String icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
    );
  }
}
