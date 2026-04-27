import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/ui/common/components/app_badge.dart';
import 'package:dawnbreaker/ui/common/components/app_pill_button.dart';
import 'package:dawnbreaker/ui/common/components/app_progress_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:flutter/material.dart';
import 'package:dawnbreaker/core/date_util.dart';

class AppTaskListItem extends StatelessWidget {
  const AppTaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  final TaskItem task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final taskProgress = task.computeProgress();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: task.color.baseColor(context)),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppTaskIconTile(
                        emoji: task.icon,
                        color: task.color,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (taskProgress is DueDate) ...[
                              const SizedBox(height: 4),
                              _DateRow(
                                taskProgress: taskProgress,
                                colors: colors,
                              ),
                              const SizedBox(height: 6),
                              AppProgressBar(
                                value: taskProgress.progress,
                                isOverdue: taskProgress.isOverdue,
                                thickness: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppPillButton(
                        label: context.l10n.homeComplete,
                        onPressed: onComplete,
                        leading: const Icon(
                          Icons.check,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.taskProgress, required this.colors});

  final DueDate taskProgress;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateUtil.format(context, taskProgress.scheduledAt);

    final AppBadgeTone tone;
    final String badgeText;

    if (taskProgress.isOverdue) {
      tone = AppBadgeTone.danger;
      badgeText = context.l10n.homeDaysOverdue(
        taskProgress.daysRemaining.abs(),
      );
    } else if (taskProgress.daysRemaining == 0) {
      tone = AppBadgeTone.warning;
      badgeText = context.l10n.homeDueToday;
    } else {
      tone = AppBadgeTone.neutral;
      badgeText = context.l10n.homeDaysRemaining(taskProgress.daysRemaining);
    }

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 11, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(dateStr, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        const SizedBox(width: 6),
        AppBadge(label: badgeText, tone: tone),
      ],
    );
  }
}
