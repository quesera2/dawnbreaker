import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppPillButtonVariant { primary, secondary }

class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppPillButtonVariant.primary,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppPillButtonVariant variant;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;

    final (bg, fg) = switch (variant) {
      AppPillButtonVariant.primary => (c.primary, c.primaryOn),
      AppPillButtonVariant.secondary => (c.surface, c.text),
    };

    final style = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: const StadiumBorder(),
      elevation: 1,
      shadowColor: c.shadow,
      textStyle: AppTextStyle.overline.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1,
      ),
      minimumSize: Size.zero,
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: _buttonContent(),
    );
  }

  Widget _buttonContent() {
    if (leading != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(data: const IconThemeData(size: 11), child: leading!),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
    } else {
      return Text(label);
    }
  }
}

@Preview()
Widget previewPillButton() => const PillButtonShowCase();

final class PillButtonShowCase extends StatelessWidget {
  const PillButtonShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Container(
      color: c.bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          AppPillButton(
            label: '完了',
            onPressed: () {},
            leading: const Icon(Icons.check),
          ),
          AppPillButton(
            label: '完了',
            variant: AppPillButtonVariant.secondary,
            onPressed: () {},
            leading: const Icon(Icons.check),
          ),
          const AppPillButton(label: '完了 (disabled)'),
        ],
      ),
    );
  }
}
