import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppBadgeTone { neutral, danger, warning, success, info, primary }

extension AppBadgeToneColors on AppBadgeTone {
  Color bgColor(AppColorScheme c) => switch (this) {
    AppBadgeTone.neutral => c.divider,
    AppBadgeTone.danger => c.dangerSoft,
    AppBadgeTone.warning => c.warningSoft,
    AppBadgeTone.success => c.successSoft,
    AppBadgeTone.info => c.infoSoft,
    AppBadgeTone.primary => c.primarySoft,
  };

  Color fgColor(AppColorScheme c) => switch (this) {
    AppBadgeTone.neutral => c.textMuted,
    AppBadgeTone.danger => c.danger,
    AppBadgeTone.warning => c.warning,
    AppBadgeTone.success => c.success,
    AppBadgeTone.info => c.info,
    AppBadgeTone.primary => c.primary,
  };
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final bg = tone.bgColor(c);
    final fg = tone.fgColor(c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: AppTextStyle.overline.copyWith(color: fg)),
    );
  }
}

@Preview()
Widget previewAllTones() => const LabelShowCase();

final class LabelShowCase extends StatelessWidget {
  const LabelShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      color: colorScheme.bg,
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      child: const Row(
        spacing: 6,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppBadge(label: '中立', tone: AppBadgeTone.neutral),
          AppBadge(label: '11日超過', tone: AppBadgeTone.danger),
          AppBadge(label: '今日', tone: AppBadgeTone.warning),
          AppBadge(label: '完了', tone: AppBadgeTone.success),
          AppBadge(label: '情報', tone: AppBadgeTone.info),
          AppBadge(label: '残り6日', tone: AppBadgeTone.primary),
        ],
      ),
    );
  }
}
