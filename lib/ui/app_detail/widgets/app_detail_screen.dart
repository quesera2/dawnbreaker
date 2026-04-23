import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_view_model.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_badge.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.appDetailTitle,
        onBack: () => context.pop(),
        actions: task != null
            ? [
                AppIconButton(
                  icon: Icons.edit_outlined,
                  label: context.l10n.appDetailEdit,
                  onTap: () => context.push('/editor', extra: task.id),
                ),
                const SizedBox(width: 4),
                AppIconButton(
                  icon: Icons.delete,
                  tone: AppIconTone.destruction,
                  onTap: viewModel.deleteTask,
                ),
                const SizedBox(width: 12),
              ]
            : null,
      ),
      backgroundColor: colors.bg,
      body: (uiState.isLoading || task == null)
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskHeader(task: task),
                  const SizedBox(height: 20),
                  _StatsAndChartCard(task: task),
                  const SizedBox(height: 28),
                  _HistorySection(task: task),
                ],
              ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppTaskIconTile(emoji: task.icon, color: task.color, size: 52),
        const SizedBox(width: 16),
        Column(
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
      ],
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
          _unitLabel(context, scheduleUnit),
        ),
        tone: AppBadgeTone.info,
      ),
    };
  }

  String _unitLabel(BuildContext context, ScheduleUnit unit) => switch (unit) {
    ScheduleUnit.day => context.l10n.editorSpanDay,
    ScheduleUnit.week => context.l10n.editorSpanWeek,
    ScheduleUnit.month => context.l10n.editorSpanMonth,
  };
}

class _StatsAndChartCard extends StatelessWidget {
  const _StatsAndChartCard({required this.task});

  final TaskItem task;

  List<int> _computeIntervals() {
    final h = task.taskHistory;
    if (h.length < 2) return [];
    return [
      for (var i = 1; i < h.length; i++)
        h[i].executedAt.difference(h[i - 1].executedAt).inDays,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final intervals = _computeIntervals();

    final daysSince = task.lastExecutedAt == null
        ? null
        : DateTime.now().difference(task.lastExecutedAt!).inDays;

    final avgInterval = intervals.isEmpty
        ? null
        : (intervals.reduce((a, b) => a + b) / intervals.length).round();

    final displayedIntervals = intervals.length > 10
        ? intervals.sublist(intervals.length - 10)
        : intervals;

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
              padding: EdgeInsetsGeometry.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCell(
                      label: context.l10n.appDetailStatsDaysSince,
                      value: daysSince?.toString() ?? '—',
                      unit: daysSince != null
                          ? context.l10n.appDetailStatsDay
                          : '',
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
                      value: avgInterval?.toString() ?? '—',
                      unit: avgInterval != null
                          ? context.l10n.appDetailStatsDay
                          : '',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (displayedIntervals.isNotEmpty) ...[
            Divider(color: colors.divider, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: IntervalBarChart(
                intervals: displayedIntervals,
                averageInterval: avgInterval != null
                    ? avgInterval.toDouble()
                    : 0,
                taskColor: task.color,
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
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyle.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyle.title1.copyWith(color: colors.text),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: AppTextStyle.body.copyWith(color: colors.textMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final history = task.taskHistory.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトルヘッダ
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              context.l10n.appDetailHistorySection.toUpperCase(),
              style: AppTextStyle.overline.copyWith(color: colors.textMuted),
            ),
            const SizedBox(width: 8),
            Text(
              '${history.length}',
              style: AppTextStyle.overline.copyWith(
                color: colors.textSubtle,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 履歴
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                for (var i = 0; i < history.length; i++)
                  _HistoryItem(
                    entry: history[i],
                    isFirst: i == 0,
                    isLast: i == history.length - 1,
                    taskColor: task.color,
                    intervalDays: i < history.length - 1
                        ? history[i].executedAt
                              .difference(history[i + 1].executedAt)
                              .inDays
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ],
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
  });

  final TaskHistory entry;
  final bool isFirst;
  final bool isLast;
  final TaskColor taskColor;
  final int? intervalDays;

  static const _dotSize = 10.0;
  static const _lineWidth = 1.5;
  static const _itemSpacing = 20.0;

  // body(15px) 行高さ ~18px でドット(10px)を縦中央に置いた上端・下端 Y
  static const _dotTopY = 4.0;
  static const _dotBottomY = _dotTopY + _dotSize; // 14.0

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).format(date);
  }

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

    return Stack(
      children: [
        // first: dotBottom→bottom、last: top→dotTop、middle: 全高
        if (!isFirst || !isLast)
          Positioned(
            left: _dotSize / 2 - _lineWidth / 2,
            width: _lineWidth,
            top: isFirst ? _dotBottomY : 0,
            bottom: isLast ? null : 0,
            height: isLast ? _dotTopY : null,
            child: ColoredBox(color: colors.divider),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: _dotDecoration(dotColor, colors.surface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(context, entry.executedAt),
                    style: AppTextStyle.body.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (intervalDays != null)
                  Text(
                    context.l10n.appDetailDaysInterval(intervalDays!),
                    style: AppTextStyle.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
            if (isFirst)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: _dotSize + 12),
                child: _CommentPlaceholder(colors: colors),
              ),
            if (!isLast) const SizedBox(height: _itemSpacing),
          ],
        ),
      ],
    );
  }
}

class _CommentPlaceholder extends StatelessWidget {
  const _CommentPlaceholder({required this.colors});

  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        context.l10n.appDetailCommentPlaceholder,
        style: AppTextStyle.caption.copyWith(color: colors.textSubtle),
      ),
    );
  }
}
