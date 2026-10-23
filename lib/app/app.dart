import 'dart:async';

import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_router.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:dawnbreaker/core/auth/session_expiry.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:dawnbreaker/ui/common/components/app_dialog.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/login/widgets/login_param.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.read(appRouterProvider);
    ref.listen(sessionExpiryProvider, (prev, next) {
      if (next == null || prev?.id == next.id) return;
      _showSessionExpired(appRouter);
    });

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

  /// どの画面にいても出せるよう、ルーターの Navigator に出す。
  /// 了承したらログアウトと同じ経路に乗せ、遷移を待ってからトークンを捨ててサインアウトする
  void _showSessionExpired(GoRouter appRouter) {
    final navigatorContext =
        appRouter.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    unawaited(
      AppDialog.show(
        navigatorContext,
        SessionExpiredMessage(
          secondaryHandler: () => appRouter.go(
            '/login',
            extra: const LoginParam(executeLogout: true),
          ),
        ),
      ),
    );
  }
}
