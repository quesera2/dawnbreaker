import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/interval_bar_chart.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:dawnbreaker/ui/common/components/app_task_list_item.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:flutter/material.dart';

typedef ButtonConfig = ({
  String primaryLabel,
  VoidCallback primaryAction,
  String? secondaryLabel,
  VoidCallback? secondaryAction,
  bool hasSecondaryArea,
});

typedef OnboardingPageData = ({OnboardingPage page, ButtonConfig buttons});

List<OnboardingPageData> buildOnboardingPages(
  BuildContext context, {
  required List<Color> pageColors,
  required OnboardingMode mode,
  required VoidCallback onNext,
  required VoidCallback onDone,
  required VoidCallback onSkip,
  required VoidCallback onRequestNotification,
}) => [
  (
    page: OnboardingPage(
      pageTitle: context.l10n.onboardingPage1Title,
      pageDescription: context.l10n.onboardingPage1Body,
      backgroundColor: pageColors[0],
      pageDetail: _OnboardingPage1Description(backgroundColor: pageColors[0]),
    ),
    buttons: _nextOnlyButtons(context, mode, onNext: onNext),
  ),
  (
    page: OnboardingPage(
      pageTitle: context.l10n.onboardingPage2Title,
      pageDescription: context.l10n.onboardingPage2Body,
      backgroundColor: pageColors[1],
      pageDetail: const _OnboardingPage2Description(),
    ),
    buttons: _nextOnlyButtons(context, mode, onNext: onNext),
  ),
  (
    page: OnboardingPage(
      pageTitle: context.l10n.onboardingPage3Title,
      pageDescription: context.l10n.onboardingPage3Title,
      backgroundColor: pageColors[2],
      pageDetail: const _OnboardingPage3Description(),
    ),
    buttons: _notificationPageButtons(
      context,
      mode,
      onNext: onNext,
      onRequestNotification: onRequestNotification,
    ),
  ),
  (
    page: OnboardingPage(
      pageTitle: context.l10n.onboardingPage4Title,
      pageDescription: context.l10n.onboardingPage4Body,
      backgroundColor: pageColors[3],
      pageDetail: const _OnboardingPage4Description(),
    ),
    buttons: _lastPageButtons(context, mode, onDone: onDone, onSkip: onSkip),
  ),
];

ButtonConfig _nextOnlyButtons(
  BuildContext context,
  OnboardingMode mode, {
  required VoidCallback onNext,
}) => (
  primaryLabel: context.l10n.onboardingNext,
  primaryAction: onNext,
  secondaryLabel: null,
  secondaryAction: null,
  hasSecondaryArea: mode == .initial,
);

ButtonConfig _notificationPageButtons(
  BuildContext context,
  OnboardingMode mode, {
  required VoidCallback onNext,
  required VoidCallback onRequestNotification,
}) => switch (mode) {
  .initial => (
    primaryLabel: context.l10n.onboardingEnableNotification,
    primaryAction: onRequestNotification,
    secondaryLabel: context.l10n.onboardingNext,
    secondaryAction: onNext,
    hasSecondaryArea: true,
  ),
  .fromSettings => (
    primaryLabel: context.l10n.onboardingNext,
    primaryAction: onNext,
    secondaryLabel: null,
    secondaryAction: null,
    hasSecondaryArea: false,
  ),
};

ButtonConfig _lastPageButtons(
  BuildContext context,
  OnboardingMode mode, {
  required VoidCallback onDone,
  required VoidCallback onSkip,
}) => switch (mode) {
  .initial => (
    primaryLabel: context.l10n.onboardingStart,
    primaryAction: onDone,
    secondaryLabel: context.l10n.commonSkip,
    secondaryAction: onSkip,
    hasSecondaryArea: true,
  ),
  .fromSettings => (
    primaryLabel: context.l10n.commonClose,
    primaryAction: onDone,
    secondaryLabel: null,
    secondaryAction: null,
    hasSecondaryArea: false,
  ),
};

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
        name: context.l10n.onboardingDemoTask1,
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
        name: context.l10n.onboardingDemoTask2,
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
        name: context.l10n.onboardingDemoTask3,
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
        name: context.l10n.onboardingDemoTask4,
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
        name: context.l10n.onboardingDemoTask5,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleArea(
              context,
              TaskItem.scheduled(
                id: 0,
                name: context.l10n.onboardingDemoTask6,
                furigana: '',
                icon: '✂️',
                color: TaskColor.blue,
                scheduleValue: 1,
                scheduleUnit: ScheduleUnit.month,
                taskHistory: [],
              ),
            ),
            const SizedBox(height: 16),
            const IntervalBarChart(
              intervals: _demoIntervals,
              averageInterval: _averageInterval,
              taskColor: TaskColor.blue,
              barAreaHeight: 160,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _titleArea(BuildContext context, TaskItem task) {
    final c = context.appColorScheme;
    return Row(
      children: [
        AppTaskIconTile(emoji: task.icon, color: task.color, size: 40),
        const SizedBox(width: 12),
        Text(task.name, style: AppTextStyle.title2.copyWith(color: c.text)),
      ],
    );
  }
}

class _OnboardingPage3Description extends StatefulWidget {
  const _OnboardingPage3Description();

  @override
  State<_OnboardingPage3Description> createState() =>
      _OnboardingPage3DescriptionState();
}

class _OnboardingPage3DescriptionState
    extends State<_OnboardingPage3Description>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _iconSize = 72.0;
  static const _iconRadius = _iconSize / 2;
  static const _iconCenter = Offset(100, 90);
  static const _rippleCount = 3;
  static const _period = 1.0 / _rippleCount;
  static const _scaleUpTime = _period * 0.18;
  static const _pulseWindow = _period * 0.9;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return SizedBox(
      width: 280,
      height: 240,
      child: AnimatedBuilder(
        animation: _controller,
        child: const _NotificationCard(iconEmoji: '🪥'),
        builder: (context, card) {
          final t = _controller.value;

          // 波紋は 1/3 サイクルごとに発火 → アイコン・通知カードを振動させる
          double iconScale = 1.0;
          double cardScale = 1.0;
          bool isScalingUp = false;
          for (int i = 0; i < _rippleCount; i++) {
            final localT = (t - i / _rippleCount + 1.0) % 1.0;
            if (localT < _pulseWindow) {
              isScalingUp = localT < _scaleUpTime;
              iconScale = _pulseScale(localT, amplitude: 0.24);
            }
            // 通知カードはディレイを入れる
            final cardLocalT = localT - _period * 0.06;
            if (cardLocalT > 0 && cardLocalT < _period * 0.75) {
              cardScale = _pulseScale(cardLocalT, amplitude: 0.1);
            }
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 波紋
              CustomPaint(
                size: const Size(280, 240),
                painter: _RipplePainter(
                  color: c.primary,
                  progress: t,
                  center: _iconCenter,
                  startRadius: _iconRadius + 4,
                  maxRadius: 190,
                  count: _rippleCount,
                ),
              ),
              // 通知アイコン
              Positioned(
                left: _iconCenter.dx - _iconRadius,
                top: _iconCenter.dy - _iconRadius,
                child: Transform.scale(
                  scale: iconScale,
                  child: Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary,
                    ),
                    child: Icon(
                      isScalingUp
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_outlined,
                      color: c.primaryOn,
                      size: 40,
                    ),
                  ),
                ),
              ),
              // 通知カード（常時表示・パルスあり）
              Positioned(
                right: 0,
                bottom: 0,
                child: Transform.scale(
                  scale: cardScale,
                  alignment: Alignment.center,
                  child: card,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 心拍風のスケーリングを行う
  static double _pulseScale(double localT, {required double amplitude}) {
    if (localT < _scaleUpTime) {
      final p = localT / _scaleUpTime;
      return 1.0 + p * p * amplitude;
    }
    if (localT < _pulseWindow) {
      final p = (localT - _scaleUpTime) / (_pulseWindow - _scaleUpTime);
      return (1.0 + amplitude) - (1.0 - (1.0 - p) * (1.0 - p)) * amplitude;
    }
    return 1.0;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.iconEmoji});

  final String iconEmoji;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Card(
      color: c.surface,
      elevation: 3,
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(iconEmoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.onboardingDemoTask3,
                      style: AppTextStyle.caption.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.notificationTaskBody,
                      style: AppTextStyle.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.color,
    required this.progress,
    required this.center,
    required this.startRadius,
    required this.maxRadius,
    required this.count,
  });

  final Color color;
  final double progress;
  final Offset center;
  final double startRadius;
  final double maxRadius;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final p = (progress + i / count) % 1.0;
      // アイコン pulse に追従するよう少し遅らせて展開開始
      if (p < 0.025) continue;
      final expand = (p - 0.025) / 0.985;
      final radius = startRadius + expand * (maxRadius - startRadius);
      final opacity = (1.0 - expand) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.color != color;
}

class _OnboardingPage4Description extends StatelessWidget {
  const _OnboardingPage4Description();

  @override
  Widget build(BuildContext context) {
    final items = [
      (color: TaskColor.red, name: context.l10n.onboardingColorRed),
      (color: TaskColor.blue, name: context.l10n.onboardingColorBlue),
      (color: TaskColor.green, name: context.l10n.onboardingColorGreen),
      (color: TaskColor.orange, name: context.l10n.onboardingColorOrange),
      (color: TaskColor.yellow, name: context.l10n.onboardingColorYellow),
      (color: TaskColor.none, name: context.l10n.onboardingColorNone),
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
    const depth = 6.0;
    return Stack(
      children: [
        // 背面カード
        Padding(
          padding: const EdgeInsets.only(left: depth, top: depth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.onColor(context),
              borderRadius: BorderRadius.circular(AppRadius.s2xl),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        // 前面カード
        Padding(
          padding: const EdgeInsets.only(right: depth, bottom: depth),
          child: DecoratedBox(
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
          ),
        ),
      ],
    );
  }
}
