import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/date_util.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/generated/l10n.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/ui/common/components/app_task_list_item.dart';
import 'package:flutter/material.dart';

List<OnboardingPage> buildOnboardingPages(BuildContext context) {
  final c = context.appColorScheme;
  final pageColors = [
    c.info,
    c.warning,
    c.successSoft,
  ].map((color) => Color.lerp(color, c.surface, 0.65)!).toList();
  return [
    OnboardingPage(
      pageTitle: S.of(context).onboardingPage1Title,
      pageDescription: S.of(context).onboardingPage1Body,
      backgroundColor: pageColors[0],
      pageDetail: _OnboardingPage1Description(backgroundColor: pageColors[0]),
    ),
    OnboardingPage(
      pageTitle: S.of(context).onboardingPage2Title,
      pageDescription: S.of(context).onboardingPage2Body,
      backgroundColor: pageColors[1],
      pageDetail: const _OnboardingPage2Description(),
    ),
    OnboardingPage(
      pageTitle: S.of(context).onboardingPage3Title,
      pageDescription: S.of(context).onboardingPage3Body,
      backgroundColor: pageColors[2],
      pageDetail: const _OnboardingPage3Description(),
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
            child: Align(alignment: Alignment.center, child: pageDetail),
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
  const _OnboardingPage1Description({required this.backgroundColor});

  final Color backgroundColor;

  static List<TaskItem> _demoTasks(DateTime now, BuildContext context) {
    return [
      TaskItem.scheduled(
        id: 0,
        name: S.of(context).onboardingDemoTask1,
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
        name: S.of(context).onboardingDemoTask2,
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
        name: S.of(context).onboardingDemoTask3,
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
        name: S.of(context).onboardingDemoTask4,
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
        name: S.of(context).onboardingDemoTask5,
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

  /// 背面にいくほど小さくなる係数
  static const _scaleStep = 0.04;

  /// リスト1列ごとのマージン
  static const _offsetStep = 56.0;

  /// 背面を透過する処理の係数
  static const _dimStep = 0.12;

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
            backgroundColor.withValues(alpha: depth * _dimStep),
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
      color: context.appColorScheme.surface,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: IntervalBarChart(
          intervals: _demoIntervals,
          averageInterval: _averageInterval,
          taskColor: TaskColor.blue,
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
    final items = [
      (color: TaskColor.red, name: S.of(context).onboardingColorRed),
      (color: TaskColor.blue, name: S.of(context).onboardingColorBlue),
      (color: TaskColor.green, name: S.of(context).onboardingColorGreen),
      (color: TaskColor.orange, name: S.of(context).onboardingColorOrange),
      (color: TaskColor.yellow, name: S.of(context).onboardingColorYellow),
      (color: TaskColor.none, name: S.of(context).onboardingColorNone),
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
        color: color.baseColor(context),
        borderRadius: BorderRadius.circular(AppRadius.s2xl),
        border: Border.all(color: color.onColor(context), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            name,
            style: AppTextStyle.caption.copyWith(
              color: color.softColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
