import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppTaskIconTile extends StatelessWidget {
  const AppTaskIconTile({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 40,
    this.isDisabled = false,
  });

  final String emoji;
  final TaskColor color;

  /// タイルのサイズ (dp)。推奨: 32 / 40 / 48 / 52
  final double size;

  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final tc = AppTaskColorScheme.of(context);
    final radius = size * 0.28;
    final softColor = tc.soft(color);
    final baseColor = tc.base(color);
    final fontSize = size * 0.55;

    Widget tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: fontSize),
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
      ),
    );

    if (isDisabled) {
      tile = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          // luminosity grayscale
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.5, 0,
        ]),
        child: tile,
      );
    }

    return tile;
  }
}

@Preview()
Widget previewTaskIconTile() => const TaskIconTileShowCase();

final class TaskIconTileShowCase extends StatelessWidget {
  const TaskIconTileShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColorScheme.of(context).bg;
    return Container(
      color: bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: const [
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
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              AppTaskIconTile(emoji: '🪴', color: TaskColor.green),
              AppTaskIconTile(
                emoji: '🪴',
                color: TaskColor.green,
                isDisabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
