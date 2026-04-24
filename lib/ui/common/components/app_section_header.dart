import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subTitle,
    this.backgroundColor,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 8),
  });

  final Widget title;
  final Widget? subTitle;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: DefaultTextStyle(
                style: AppTextStyle.overline.copyWith(
                  color: colors.textMuted,
                  overflow: TextOverflow.ellipsis,
                ),
                child: title,
              ),
            ),
            if (subTitle != null) ...[
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: AppTextStyle.overline.copyWith(color: colors.textSubtle),
                child: subTitle!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget previewProgressBar() => const AppSectionHeaderShowCase();

final class AppSectionHeaderShowCase extends StatelessWidget {
  const AppSectionHeaderShowCase({super.key});

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
            const AppSectionHeader(title: Text('タイトルのみ')),
            const AppSectionHeader(
              title: Text('タイトルのみ長い文章長い文章長い文章長い文章長い文章長い文章長い文章'),
            ),
            const AppSectionHeader(
              title: Text('タイトルとサブタイトル'),
              subTitle: Text('サブタイトル'),
            ),
            const AppSectionHeader(
              title: Text('前景色・背景色指定', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
