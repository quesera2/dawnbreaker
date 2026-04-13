import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('タスク')),
      body: uiState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: uiState.tasks.length,
              itemBuilder: (context, index) {
                final task = uiState.tasks[index];
                return _TaskListItem(task: task);
              },
            ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  const _TaskListItem({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduledAt = task.scheduledAt;

    final now = DateTime.now();
    double? progress;
    int? daysRemaining;
    bool isOverdue = false;

    if (scheduledAt != null) {
      final totalDays = scheduledAt.difference(task.registeredAt).inDays;
      final elapsedDays = now.difference(task.registeredAt).inDays;
      daysRemaining = scheduledAt.difference(now).inDays;
      isOverdue = now.isAfter(scheduledAt);
      if (totalDays > 0) {
        progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
      }
    }

    final progressColor = isOverdue
        ? colorScheme.error
        : (progress != null && progress > 0.5)
        ? colorScheme.tertiary
        : colorScheme.primary;
    final dueDateColor =
        isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;
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
              Row(
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
                  Expanded(
                    child: Text(task.name, style: theme.textTheme.titleMedium),
                  ),
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.registeredAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (scheduledAt != null) ...[
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
                      color: dueDateColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(scheduledAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: dueDateColor,
                      ),
                    ),
                  ],
                ],
              ),
              if (progress != null && daysRemaining != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOverdue
                          ? '${daysRemaining.abs()}日超過'
                          : '残り$daysRemaining日',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
