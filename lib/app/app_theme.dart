import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

ThemeData createThemeData(BuildContext context) {
  final colorScheme = context.appColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colorScheme.primary,
      brightness: MediaQuery.platformBrightnessOf(context),
    ),
    scaffoldBackgroundColor: colorScheme.bg,
    canvasColor: colorScheme.bg,
    hintColor: colorScheme.textMuted,
    iconTheme: IconThemeData(color: colorScheme.text),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.bg,
      foregroundColor: colorScheme.text,
      iconTheme: IconThemeData(color: colorScheme.text),
      titleTextStyle: AppTextStyle.body.copyWith(
        color: colorScheme.text,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.divider),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: colorScheme.borderStrong,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.border),
      ),
      titleTextStyle: AppTextStyle.headline.copyWith(color: colorScheme.text),
      contentTextStyle: AppTextStyle.caption.copyWith(
        color: colorScheme.textMuted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.text,
      contentTextStyle: AppTextStyle.body.copyWith(
        color: colorScheme.textInverse,
      ),
      actionTextColor: colorScheme.primaryInverse,
    ),
  );
}
