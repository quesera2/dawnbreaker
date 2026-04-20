import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
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
        iconSize: 20,
      ),
    );
  }
}
