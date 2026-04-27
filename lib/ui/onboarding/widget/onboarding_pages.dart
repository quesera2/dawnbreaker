import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/date_util.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_task_list_item.dart';
import 'package:flutter/material.dart';

List<OnboardingPage> buildOnboardingPages(BuildContext context) {
  final c = context.appColorScheme;
  final l10n = context.l10n;
  return [
    OnboardingPage(
      pageTitle: l10n.onboardingPage1Title,
      pageDescription: l10n.onboardingPage1Body,
      pageDetail: const _OnboardingPage1Description(),
      backgroundColor: Color.lerp(c.danger, c.surface, 0.65)!,
    ),
    OnboardingPage(
      pageTitle: l10n.onboardingPage2Title,
      pageDescription: l10n.onboardingPage2Body,
      pageDetail: const _OnboardingPage2Description(),
      backgroundColor: Color.lerp(c.warning, c.surface, 0.65)!,
    ),
    OnboardingPage(
      pageTitle: l10n.onboardingPage3Title,
      pageDescription: l10n.onboardingPage3Body,
      pageDetail: const _OnboardingPage3Description(),
      backgroundColor: Color.lerp(c.success, c.surface, 0.65)!,
    ),
  ];
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.pageTitle,
    required this.pageDescription,
    required this.pageDetail,
    required this.backgroundColor,
  });

  final String pageTitle;
  final String pageDescription;
  final Widget pageDetail;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(alignment: Alignment.center, child: pageDetail),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100),
            child: Text(
              pageTitle,
              style: AppTextStyle.largeTitle.copyWith(color: colorScheme.text),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Text(
              pageDescription,
              style: AppTextStyle.body.copyWith(color: colorScheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage1Description extends StatelessWidget {
  const _OnboardingPage1Description();

  static List<TaskItem> _demoTasks(DateTime now, BuildContext context) {
    final l10n = context.l10n;
    return [
      TaskItem.scheduled(
        id: 0,
        name: l10n.onboardingDemoTask1,
        furigana: '',
        icon: '🐝',
        color: TaskColor.yellow,
        scheduleValue: 9,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [
          TaskHistory(
            id: 0,
            executedAt: DateTime(now.year, now.month - 6, now.day),
            comment: null,
          ),
        ],
      ),
      TaskItem.scheduled(
        id: 0,
        name: l10n.onboardingDemoTask2,
        furigana: '',
        icon: '🚗',
        color: TaskColor.red,
        scheduleValue: 6,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [
          TaskHistory(
            id: 0,
            executedAt: DateTime(now.year, now.month - 5, now.day - 1),
            comment: null,
          ),
        ],
      ),
      TaskItem.scheduled(
        id: 0,
        name: l10n.onboardingDemoTask3,
        furigana: '',
        icon: '🪥',
        color: TaskColor.orange,
        scheduleValue: 1,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [
          TaskHistory(
            id: 0,
            executedAt: DateTime(now.year, now.month, now.day - 3),
            comment: null,
          ),
        ],
      ),
      TaskItem.scheduled(
        id: 0,
        name: l10n.onboardingDemoTask4,
        furigana: '',
        icon: '🧪',
        color: TaskColor.green,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        taskHistory: [
          TaskHistory(
            id: 0,
            executedAt: DateTime(now.year, now.month, now.day - 7),
            comment: null,
          ),
        ],
      ),
      TaskItem.scheduled(
        id: 0,
        name: l10n.onboardingDemoTask5,
        furigana: '',
        icon: '👟',
        color: TaskColor.blue,
        scheduleValue: 1,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [
          TaskHistory(
            id: 0,
            executedAt: DateTime(now.year, now.month - 1, now.day),
            comment: null,
          ),
        ],
      ),
    ];
  }

  static const _scaleStep = 0.04;
  static const _offsetStep = 56.0;
  static const _dimStep = 0.05;

  @override
  Widget build(BuildContext context) {
    final tasks = _demoTasks(DateTime.now().truncateTime, context);
    return Padding(
      padding: EdgeInsets.only(bottom: (tasks.length - 1) * _offsetStep),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < tasks.length; i++)
            _buildItem(tasks[i], depth: tasks.length - 1 - i),
        ],
      ),
    );
  }

  Widget _buildItem(TaskItem task, {required int depth}) {
    return Transform.translate(
      offset: Offset(0, depth * _offsetStep),
      child: Transform.scale(
        scale: 1.0 - depth * _scaleStep,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: depth * _dimStep),
            BlendMode.srcATop,
          ),
          child: AppTaskListItem(task: task),
        ),
      ),
    );
  }
}

class _OnboardingPage2Description extends StatelessWidget {
  const _OnboardingPage2Description();

  static const _demoIntervals = [35, 29, 33, 27, 31, 38, 28, 32, 30, 26];
  static const _averageInterval = 30.9;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.appColorScheme.bgSubtle,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: IntervalBarChart(
          intervals: _demoIntervals,
          averageInterval: _averageInterval,
          taskColor: TaskColor.orange,
          barAreaHeight: 160,
        ),
      ),
    );
  }
}

class _OnboardingPage3Description extends StatelessWidget {
  const _OnboardingPage3Description();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (color: TaskColor.red, name: l10n.onboardingColorRed),
      (color: TaskColor.blue, name: l10n.onboardingColorBlue),
      (color: TaskColor.green, name: l10n.onboardingColorGreen),
      (color: TaskColor.orange, name: l10n.onboardingColorOrange),
      (color: TaskColor.yellow, name: l10n.onboardingColorYellow),
      (color: TaskColor.none, name: l10n.onboardingColorNone),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final item in items)
          _taskColorCard(context: context, color: item.color, name: item.name),
      ],
    );
  }

  Widget _taskColorCard({
    required BuildContext context,
    required TaskColor color,
    required String name,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.softColor(context),
        borderRadius: BorderRadius.circular(AppRadius.s2xl),
        border: Border.all(color: color.onColor(context), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            name,
            style: AppTextStyle.caption.copyWith(color: color.onColor(context)),
          ),
        ),
      ),
    );
  }
}
