import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

ThemeData createThemeData(BuildContext context) {
  final brightness = MediaQuery.platformBrightnessOf(context);
  final c = brightness == Brightness.dark
      ? AppColorScheme.dark
      : AppColorScheme.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    hintColor: c.textMuted,
    iconTheme: IconThemeData(color: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      iconTheme: IconThemeData(color: c.text),
      titleTextStyle: AppTextStyle.body.copyWith(
        color: c.text,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 1,
      shadowColor: c.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.divider),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: c.borderStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.border),
      ),
      titleTextStyle: AppTextStyle.headline.copyWith(color: c.text),
      contentTextStyle: AppTextStyle.caption.copyWith(color: c.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: AppTextStyle.body.copyWith(color: c.textInverse),
      actionTextColor: c.primaryInverse,
    ),
  );
}
