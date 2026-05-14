import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_screen.dart';
import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_screen.dart';
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
  final initialLocation = isOnboardingCompleted ? '/home' : '/onboarding';

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
            AppDetailScreen(taskId: int.parse(state.pathParameters['taskId']!)),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => EditorScreen(
              taskId: int.parse(state.pathParameters['taskId']!),
            ),
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
        ],
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
