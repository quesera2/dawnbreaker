import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
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
                  fontWeight: .w700,
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

final class AppSectionHeaderShowCase extends PreviewShowCase {
  const AppSectionHeaderShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) => const SizedBox(
    width: 320,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        AppSectionHeader(title: Text('タイトルのみ')),
        AppSectionHeader(title: Text('タイトルのみ長い文章長い文章長い文章長い文章長い文章長い文章長い文章')),
        AppSectionHeader(title: Text('タイトルとサブタイトル'), subTitle: Text('サブタイトル')),
        AppSectionHeader(
          title: Text('前景色・背景色指定', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      ],
    ),
  );
}
