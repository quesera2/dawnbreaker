import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.isOverdue = false,
    this.thickness = 3,
  });

  /// 進捗 (0.0 〜 1.0)
  final double value;

  final bool isOverdue;

  /// バーの太さ (dp)
  final double thickness;

  static ({Color base, Color soft}) _barColors(
    AppColorScheme c,
    double value,
    bool isOverdue,
  ) {
    if (isOverdue) return (base: c.danger, soft: c.dangerSoft);
    if (value >= 0.75) return (base: c.warning, soft: c.warningSoft);
    if (value >= 0.5) return (base: c.success, soft: c.successSoft);
    return (base: c.info, soft: c.infoSoft);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final (:base, :soft) = _barColors(c, value, isOverdue);
    final highlightColor = Color.lerp(base, soft, 0.6)!;
    final clamped = value.clamp(0.0, 1.0);

    if (value >= 1.0) {
      return _BlinkBar(
        clamped: clamped,
        baseColor: base,
        highlightColor: highlightColor,
        trackBg: c.trackBg,
        thickness: thickness,
      );
    }
    if (value <= 0.25) {
      return _StaticBar(
        clamped: clamped,
        baseColor: base,
        trackBg: c.trackBg,
        thickness: thickness,
      );
    }
    return _GlimmerBar(
      clamped: clamped,
      baseColor: base,
      highlightColor: highlightColor,
      trackBg: c.trackBg,
      thickness: thickness,
    );
  }
}

class _StaticBar extends StatelessWidget {
  const _StaticBar({
    required this.clamped,
    required this.baseColor,
    required this.trackBg,
    required this.thickness,
  });

  final double clamped;
  final Color baseColor;
  final Color trackBg;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: thickness,
        color: trackBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          heightFactor: 1.0,
          child: ColoredBox(color: baseColor),
        ),
      ),
    );
  }
}

class _GlimmerBar extends StatefulWidget {
  const _GlimmerBar({
    required this.clamped,
    required this.baseColor,
    required this.highlightColor,
    required this.trackBg,
    required this.thickness,
  });

  final double clamped;
  final Color baseColor;
  final Color highlightColor;
  final Color trackBg;
  final double thickness;

  @override
  State<_GlimmerBar> createState() => _GlimmerBarState();
}

class _GlimmerBarState extends State<_GlimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase 1 (0.0→0.8): グラデーションが右へ伸長
  late final Animation<double> _phase1;

  // Phase 2 (0.8→1.0): フェードアウト
  late final Animation<double> _phase2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _phase1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _phase2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: widget.thickness,
        color: widget.trackBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widget.clamped,
          heightFactor: 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final width = constraints.maxWidth * _phase1.value;
                  final alpha = 1.0 - _phase2.value;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: widget.baseColor),
                      ),
                      Container(
                        width: width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              widget.baseColor.withValues(alpha: alpha),
                              widget.highlightColor.withValues(alpha: alpha),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BlinkBar extends StatefulWidget {
  const _BlinkBar({
    required this.clamped,
    required this.baseColor,
    required this.highlightColor,
    required this.trackBg,
    required this.thickness,
  });

  final double clamped;
  final Color baseColor;
  final Color highlightColor;
  final Color trackBg;
  final double thickness;

  @override
  State<_BlinkBar> createState() => _BlinkBarState();
}

class _BlinkBarState extends State<_BlinkBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        final blendedColor = Color.lerp(
          widget.highlightColor,
          widget.baseColor,
          t,
        )!;
        // base側（t=1, 強烈な色）でグロー最大
        final glowAlpha = t * 0.25;

        return Container(
          height: widget.thickness,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withValues(alpha: glowAlpha),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              color: widget.trackBg,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widget.clamped,
                heightFactor: 1.0,
                child: ColoredBox(color: blendedColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

@Preview()
Widget previewProgressBar() => const ProgressBarShowCase();

final class ProgressBarShowCase extends StatelessWidget {
  const ProgressBarShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Container(
      color: c.bg,
      padding: const EdgeInsets.all(24),
      child: const SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            AppProgressBar(value: 0.15),
            AppProgressBar(value: 0.25),
            AppProgressBar(value: 0.55),
            AppProgressBar(value: 0.85),
            AppProgressBar(value: 1.0, isOverdue: false),
            AppProgressBar(value: 1.0, isOverdue: true),
          ],
        ),
      ),
    );
  }
}
