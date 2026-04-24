import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppProgressBar extends StatefulWidget {
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

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Duration get _duration => widget.isOverdue
      ? const Duration(milliseconds: 500)
      : const Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..repeat(reverse: widget.isOverdue);
  }

  @override
  void didUpdateWidget(AppProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOverdue != widget.isOverdue) {
      _controller
        ..duration = _duration
        ..repeat(reverse: widget.isOverdue);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _barColor(AppColorScheme c) {
    if (widget.isOverdue) return c.danger;
    if (widget.value >= 0.75) return c.warning;
    if (widget.value >= 0.5) return c.success;
    return c.info;
  }

  Color _barSoftColor(AppColorScheme c) {
    if (widget.isOverdue) return c.dangerSoft;
    if (widget.value >= 0.75) return c.warningSoft;
    if (widget.value >= 0.5) return c.successSoft;
    return c.infoSoft;
  }

  Color _barHighlightColor(AppColorScheme c) =>
      Color.lerp(_barColor(c), _barSoftColor(c), 0.6)!;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final baseColor = _barColor(c);
    final highlightColor = _barHighlightColor(c);
    final clamped = widget.value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: widget.thickness,
        color: c.trackBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          heightFactor: 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (widget.isOverdue) {
                    // 期限切れの場合は点滅
                    return ColoredBox(
                      color: Color.lerp(
                        highlightColor,
                        baseColor,
                        _controller.value,
                      )!,
                    );
                  }

                  // Phase 1 (0.0→0.7): グラデーションが右へ伸長
                  // Phase 2 (0.7→1.0): フェードアウト
                  final t = _controller.value;
                  final double width;
                  final double alpha;
                  if (t <= 0.7) {
                    width = constraints.maxWidth * (t / 0.7);
                    alpha = 1.0;
                  } else {
                    width = constraints.maxWidth;
                    alpha = 1.0 - (t - 0.7) / 0.3;
                  }

                  return Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: baseColor)),
                      Container(
                        width: width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              baseColor.withValues(alpha: alpha),
                              highlightColor.withValues(alpha: alpha),
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
            AppProgressBar(value: 0.2),
            AppProgressBar(value: 0.55),
            AppProgressBar(value: 0.85),
            AppProgressBar(value: 1.0, isOverdue: true),
          ],
        ),
      ),
    );
  }
}
