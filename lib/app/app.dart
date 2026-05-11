import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_router.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  var _channelsSetup = false;

  @override
  Widget build(BuildContext context) {
    final appRouter = ref.read(appRouterProvider);
    final notificationService = ref.read(notificationServiceProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.title,
      builder: (context, child) {
        if (!_channelsSetup) {
          _channelsSetup = true;
          notificationService.setupChannels(context);
        }
        return ColoredBox(color: context.appColorScheme.bg, child: child!);
      },
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
