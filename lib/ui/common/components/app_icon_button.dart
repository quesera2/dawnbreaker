import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.md);
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Ink(
            height: 36,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: borderRadius,
            ),
            child: Center(widthFactor: 1.0, child: _buttonContent(colors)),
          ),
        ),
      ),
    );
  }

  Widget _buttonContent(AppColorScheme colors) {
    if (label == null) {
      return Icon(icon, size: 16, color: colors.text);
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Icon(icon, size: 16, color: colors.text),
          Text(
            label!,
            style: AppTextStyle.caption.copyWith(color: colors.text),
          ),
        ],
      );
    }
  }
}

@Preview()
Widget previewIconButton() => IconButtonShowCase();

final class IconButtonShowCase extends StatelessWidget {
  const IconButtonShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      color: colorScheme.bg,
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      child: Row(
        spacing: 6,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconButton(icon: Icons.add_ic_call_outlined, onTap: () {}),
          AppIconButton(icon: Icons.edit, label: '編集', onTap: () {}),
        ],
      ),
    );
  }
}
