import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_screen.dart';
import 'package:dawnbreaker/ui/color_label/widgets/color_label_screen.dart';
import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:dawnbreaker/ui/login/widgets/login_screen.dart';
import 'package:dawnbreaker/ui/notification_intro/widgets/notification_intro_screen.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_screen.dart';
import 'package:dawnbreaker/ui/settings/display_settings/widget/display_settings_screen.dart';
import 'package:dawnbreaker/ui/settings/widget/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final preferencesManager = ref.read(preferencesManagerProvider);
  final isOnboardingCompleted = preferencesManager.get(
    onboardingCompleteKey,
    defaultValue: false,
  );
  // 監視ではなく 1 度だけ読む。ユーザーが切り替わる契機はゲスト作成・ログアウト・
  // アカウント削除しかなく、いずれも遷移先を知っているコードが命令的に遷移するため。
  // 監視すると切り替わりのたびに GoRouter ごと作り直されてしまう
  final user = ref.read(currentUserProvider);
  final initialLocation = switch (user) {
    SignedInUser() => '/home',
    NoLogin() => isOnboardingCompleted ? '/login' : '/onboarding',
  };

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(path: 'new_task', builder: (_, _) => const EditorScreen()),
        ],
      ),
      GoRoute(
        path: '/app-detail/:taskId',
        builder: (_, state) =>
            AppDetailScreen(taskId: state.pathParameters['taskId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                EditorScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'licenses',
            builder: (context, _) => Theme(
              data: Theme.of(
                context,
              ).copyWith(cardColor: context.appColorScheme.bg),
              child: const LicensePage(),
            ),
          ),
          GoRoute(
            path: 'color-labels',
            builder: (_, _) => const ColorLabelScreen(),
          ),
          GoRoute(
            path: 'display',
            builder: (_, _) => const DisplaySettingsScreen(),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/notification-intro',
        builder: (_, _) => const NotificationIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, state) => OnboardingScreen(
          mode: state.extra as OnboardingMode? ?? OnboardingMode.initial,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
