import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_router.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.read(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.title,
      builder: (context, child) =>
          ColoredBox(color: context.appColorScheme.bg, child: child!),
      theme: createThemeData(context),
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
