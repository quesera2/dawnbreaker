import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/router.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppColorScheme.of(context);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.title,
      theme: ThemeData(
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
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
