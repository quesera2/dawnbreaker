import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_stats.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_view_model.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/ui/common/components/app_badge.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_list_cell.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/home/widgets/task_complete_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDetailScreen extends ConsumerStatefulWidget {
  const AppDetailScreen({super.key, required this.taskId});

  final int taskId;

  @override
  ConsumerState<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends ConsumerState<AppDetailScreen>
    with MessagesListenMixin<AppDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = appDetailViewModelProvider(taskId: widget.taskId);
    listenMessages(provider);

    ref.listen(provider.select((s) => s.shouldPop), (_, shouldPop) {
      if (shouldPop) context.pop();
    });

    final uiState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    final colors = context.appColorScheme;
    final task = uiState.task;
    final historyStats = uiState.historyStats;
    final historyAndInterval = historyStats?.historyAndInterval ?? [];
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 3.0,
            shadowColor: colors.shadow.withValues(alpha: 0.2),
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: AppIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => context.pop(),
              ),
            ),
            title: Text(context.l10n.appDetailTitle),
            actions: task != null
                ? [
                    AppIconButton(
                      icon: Icons.edit_outlined,
                      label: context.l10n.appDetailEdit,
                      onTap: () =>
                          context.push('/app-detail/${widget.taskId}/edit'),
                    ),
                    AppIconButton(
                      icon: Icons.delete,
                      label: context.l10n.appDetailDelete,
                      tone: AppIconTone.destruction,
                      onTap: viewModel.showDeleteTaskDialog,
                    ),
                    const SizedBox(width: 12),
                  ]
                : null,
            bottom: task != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(76),
                    child: _TaskHeader(task: task),
                  )
                : null,
          ),
          if (!uiState.isLoading && task != null && historyStats != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _StatsAndChartCard(
                  taskColor: task.color,
                  daysSinceLastExecution: uiState.daysSinceLastExecution,
                  averageIntervalDays: uiState.averageIntervalDays,
                  historyStats: historyStats,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AppSectionHeader(
                title: Text(context.l10n.appDetailHistorySection.toUpperCase()),
                subTitle: Text(historyAndInterval.length.toString()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: historyAndInterval.length,
                itemBuilder: (context, i) {
                  final (entry, intervalDays) = historyAndInterval[i];
                  return _HistoryItem(
                    entry: entry,
                    isFirst: i == 0,
                    isLast: i == historyAndInterval.length - 1,
                    taskColor: task.color,
                    intervalDays: intervalDays,
                    onTap: () => _showEditSheet(task, entry),
                  );
                },
              ),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: 20 + bottomPadding)),
          ],
        ],
      ),
    );
  }

  void _showEditSheet(TaskItem task, TaskHistory entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => TaskCompleteSheet(
        task: task,
        initialDate: entry.executedAt,
        initialComment: entry.comment,
        onConfirm: (date, comment) => ref
            .read(appDetailViewModelProvider(taskId: widget.taskId).notifier)
            .updateExecution(entry, executedAt: date, comment: comment),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          AppTaskIconTile(emoji: task.icon, color: task.color, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: AppTextStyle.title2.copyWith(color: colors.text),
                ),
                const SizedBox(height: 4),
                _TypeBadge(task: task),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return switch (task) {
      IrregularTaskItem() => AppBadge(
        label: context.l10n.appDetailTypeBadgeIrregular,
        tone: AppBadgeTone.neutral,
      ),
      PeriodTaskItem() => AppBadge(
        label: context.l10n.appDetailTypeBadgePeriod,
        tone: AppBadgeTone.success,
      ),
      ScheduledTaskItem(:final scheduleValue, :final scheduleUnit) => AppBadge(
        label: context.l10n.appDetailTypeBadgeScheduled(
          scheduleValue,
          scheduleUnit.label(context),
        ),
        tone: AppBadgeTone.info,
      ),
    };
  }
}

class _StatsAndChartCard extends StatelessWidget {
  const _StatsAndChartCard({
    required this.taskColor,
    required this.daysSinceLastExecution,
    required this.averageIntervalDays,
    required this.historyStats,
  });

  final TaskColor taskColor;
  final int? daysSinceLastExecution;
  final int? averageIntervalDays;
  final TaskHistoryStats historyStats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsetsGeometry.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCell(
                      label: context.l10n.appDetailStatsDaysSince,
                      value: daysSinceLastExecution,
                      unit: context.l10n.commonUnitDay,
                    ),
                  ),
                  VerticalDivider(
                    color: colors.divider,
                    width: 1,
                    thickness: 1,
                  ),
                  Expanded(
                    child: _StatCell(
                      label: context.l10n.appDetailStatsAvgInterval,
                      value: averageIntervalDays,
                      unit: context.l10n.commonUnitDay,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (historyStats.averageIntervalDays != null) ...[
            Divider(color: colors.divider, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: IntervalBarChart(
                intervals: historyStats.historyAndInterval
                    .take(10)
                    .map((e) => e.$2)
                    .nonNulls
                    .toList(),
                averageInterval: historyStats.averageIntervalDays ?? 0,
                taskColor: taskColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final int? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyle.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: 8),
        _valueText(colors),
      ],
    );
  }

  Widget _valueText(AppColorScheme colors) {
    if (value == null) {
      return Text('—', style: AppTextStyle.title1.copyWith(color: colors.text));
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value.toString(),
            style: AppTextStyle.title1.copyWith(color: colors.text),
          ),
          if (unit.isNotEmpty)
            TextSpan(
              text: unit,
              style: AppTextStyle.body.copyWith(color: colors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.taskColor,
    required this.intervalDays,
    this.onTap,
  });

  final TaskHistory entry;
  final bool isFirst;
  final bool isLast;
  final TaskColor taskColor;
  final int? intervalDays;
  final VoidCallback? onTap;

  static const _dotSize = 10.0;
  static const _lineWidth = 1.5;
  static const _paddingH = 20.0;
  static const _paddingV = 14.0;
  static const _dotTopY = _paddingV + 4.0;
  static const _dotBottomY = _dotTopY + _dotSize;
  static const _lineLeft = _paddingH + _dotSize / 2 - _lineWidth / 2;

  AppListCellType get _type => switch ((isFirst, isLast)) {
    (true, true) => .single,
    (true, false) => .top,
    (false, true) => .bottom,
    _ => .middle,
  };

  BoxDecoration _dotDecoration(Color dotColor, Color surface) => isFirst
      ? BoxDecoration(color: dotColor, shape: BoxShape.circle)
      : BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dotColor, width: _lineWidth),
          color: surface,
        );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final dotColor = taskColor.baseColor(context);

    return AppListCell(
      type: _type,
      onTap: onTap,
      child: Stack(
        children: [
          if (!isFirst || !isLast)
            Positioned(
              left: _lineLeft,
              width: _lineWidth,
              top: isFirst ? _dotBottomY : 0,
              bottom: isLast ? null : 0,
              height: isLast ? _dotTopY : null,
              child: ColoredBox(color: colors.divider),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _paddingH,
              _paddingV,
              _paddingH,
              entry.comment == null ? _paddingV : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: _dotDecoration(dotColor, colors.surface),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateUtil.format(context, entry.executedAt),
                        style: AppTextStyle.body.copyWith(
                          color: colors.text,
                          fontWeight: isFirst
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (intervalDays != null)
                      Text(
                        intervalDays! == 0
                            ? context.l10n.commonToday
                            : context.l10n.appDetailDaysInterval(intervalDays!),
                        style: AppTextStyle.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (entry.comment case final comment?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: _dotSize + 12),
                    child: _HistoryComment(comment: comment),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryComment extends StatelessWidget {
  const _HistoryComment({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          comment,
          style: AppTextStyle.caption.copyWith(color: colors.textSubtle),
        ),
      ),
    );
  }
}
