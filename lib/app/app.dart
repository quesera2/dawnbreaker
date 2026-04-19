import 'package:dawnbreaker/app/router.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final _colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  static final _theme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.surface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.title,
      theme: _theme,
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
