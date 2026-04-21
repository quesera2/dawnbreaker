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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        side: BorderSide(color: colors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: label == null
          ? Icon(icon, size: 16)
          : Row(
              spacing: 10,
              children: [
                Icon(icon, size: 16),
                Text(label!, style: AppTextStyle.caption),
              ],
            ),
    );
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
