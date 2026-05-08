import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_stats.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_view_model.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_history_item.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/ui/common/components/app_badge.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
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
    final task = uiState.task;
    final historyStats = uiState.historyStats;

    return Scaffold(
      backgroundColor: context.appColorScheme.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(task, viewModel),
          if (!uiState.isLoading && task != null && historyStats != null)
            ..._buildContentAreas(
              task,
              historyStats,
              uiState.daysSinceLastExecution,
              uiState.averageIntervalDays,
              viewModel,
            ),
        ],
      ),
      bottomNavigationBar: task != null
          ? _RecordExecutionBar(
              tintColor: task.color,
              onTap: () => TaskCompleteSheet.show(
                context,
                task: task,
                onConfirm: (date, comment) =>
                    viewModel.recordExecution(task, date, comment),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(TaskItem? task, AppDetailViewModel viewModel) {
    final colors = context.appColorScheme;
    return SliverAppBar(
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
                onTap: () => context.push('/app-detail/${widget.taskId}/edit'),
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
    );
  }

  List<Widget> _buildContentAreas(
    TaskItem task,
    TaskHistoryStats historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
    AppDetailViewModel viewModel,
  ) {
    return [
      _statsArea(
        task,
        historyStats,
        daysSinceLastExecution,
        averageIntervalDays,
      ),
      _historyArea(task, historyStats.historyAndInterval, viewModel),
      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
    ];
  }

  Widget _statsArea(
    TaskItem task,
    TaskHistoryStats historyStats,
    int? daysSinceLastExecution,
    int? averageIntervalDays,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _StatsAndChartCard(
          taskColor: task.color,
          daysSinceLastExecution: daysSinceLastExecution,
          averageIntervalDays: averageIntervalDays,
          historyStats: historyStats,
        ),
      ),
    );
  }

  Widget _historyArea(
    TaskItem task,
    List<(TaskHistory, int?)> historyAndInterval,
    AppDetailViewModel viewModel,
  ) {
    return SliverMainAxisGroup(
      slivers: [
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
              return AppDetailHistoryItem(
                entry: entry,
                isFirst: i == 0,
                isLast: i == historyAndInterval.length - 1,
                taskColor: task.color,
                intervalDays: intervalDays,
                onTap: () => _showEditSheet(task, entry, viewModel),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditSheet(
    TaskItem task,
    TaskHistory entry,
    AppDetailViewModel viewModel,
  ) {
    TaskCompleteSheet.show(
      context,
      task: task,
      initialDate: entry.executedAt,
      initialComment: entry.comment,
      onConfirm: (date, comment) =>
          viewModel.updateExecution(entry, executedAt: date, comment: comment),
      onDelete: () => viewModel.deleteExecution(task, entry),
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

class _RecordExecutionBar extends StatelessWidget {
  const _RecordExecutionBar({required this.tintColor, required this.onTap});

  final VoidCallback onTap;
  final TaskColor tintColor;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: AppButton(
        label: context.l10n.appDetailRecordCompletion,
        onPressed: onTap,
        fullWidth: true,
        size: AppButtonSize.large,
        tintColor: tintColor,
      ),
    );
  }
}
