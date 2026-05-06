import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppTaskIconTile extends StatelessWidget {
  const AppTaskIconTile({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 40,
  });

  final String emoji;
  final TaskColor color;

  /// タイルのサイズ (dp)。推奨: 32 / 40 / 48 / 52
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final softColor = color.softColor(context);
    final baseColor = color.baseColor(context);
    final fontSize = size * 0.55;

    final borderRadius = BorderRadius.circular(radius);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: softColor),

            // グロー表現
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.2),
                  radius: 1.8,
                  colors: [
                    baseColor.withValues(alpha: 0.0),
                    baseColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),

            // 外ボーダー
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: baseColor.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),

            Center(
              child: Text(emoji, style: TextStyle(fontSize: fontSize)),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget previewTaskIconTile() => const TaskIconTileShowCase();

final class TaskIconTileShowCase extends StatelessWidget {
  const TaskIconTileShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = context.appColorScheme.bg;
    return PreviewWrapper(
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                AppTaskIconTile(emoji: '🚗', color: TaskColor.none),
                AppTaskIconTile(emoji: '🌿', color: TaskColor.red),
                AppTaskIconTile(emoji: '❄️', color: TaskColor.blue),
                AppTaskIconTile(emoji: '🐝', color: TaskColor.yellow),
                AppTaskIconTile(emoji: '🪴', color: TaskColor.green),
                AppTaskIconTile(emoji: '🧺', color: TaskColor.orange),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                AppTaskIconTile(emoji: '🚗', color: TaskColor.none, size: 32),
                AppTaskIconTile(emoji: '🚗', color: TaskColor.none),
                AppTaskIconTile(emoji: '🚗', color: TaskColor.none, size: 48),
                AppTaskIconTile(emoji: '🚗', color: TaskColor.none, size: 52),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
