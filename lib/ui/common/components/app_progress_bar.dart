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

  Color _barColor(AppColorScheme c) {
    if (isOverdue) return c.danger;
    if (value >= 0.75) return c.warning;
    if (value >= 0.5) return c.success;
    return c.info;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final barColor = _barColor(c);
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: thickness,
        color: c.trackBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          heightFactor: 1.0,
          child: ColoredBox(color: barColor),
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
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const AppProgressBar(value: 0.2),
            const AppProgressBar(value: 0.55),
            const AppProgressBar(value: 0.85),
            const AppProgressBar(value: 1.0, isOverdue: true),
          ],
        ),
      ),
    );
  }
}
