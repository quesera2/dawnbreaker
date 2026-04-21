import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return IconButton.outlined(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        side: BorderSide(color: colors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: EdgeInsetsGeometry.all(0),
        fixedSize: Size(32, 32),
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
        ],
      ),
    );
  }
}
