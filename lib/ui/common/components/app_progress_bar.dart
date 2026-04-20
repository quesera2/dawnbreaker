import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.isOverdue = false,
    this.thickness = 3,
  });

  /// 進捗 (0.0 〜 1.0)
  final double value;

  /// バーの色。null の場合は primary を使用。isOverdue=true のときは danger で上書き。
  final Color? color;

  final bool isOverdue;

  /// バーの太さ (dp)
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final barColor = isOverdue ? c.danger : (color ?? c.primary);
    final clamped = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Container(
          height: thickness,
          width: totalWidth,
          decoration: BoxDecoration(
            color: c.trackBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: totalWidth * clamped,
              height: thickness,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: isOverdue
                    ? [
                        BoxShadow(
                          color: c.danger.withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
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
    final c = AppColorScheme.of(context);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            AppProgressBar(value: 0.2, color: c.primary),
            AppProgressBar(value: 0.55, color: c.success),
            AppProgressBar(value: 0.85, color: c.warning),
            const AppProgressBar(value: 1.0, isOverdue: true),
          ],
        ),
      ),
    );
  }
}
