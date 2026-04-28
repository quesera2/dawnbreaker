import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_screen.dart';
import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final preferencesManager = ref.read(preferencesManagerProvider);
  final isOnboardingCompleted = preferencesManager.getBool(.onboardingComplete);
  final initialLocation = isOnboardingCompleted ? '/home' : '/onboarding';

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'new_task',
            builder: (_, __) => const EditorScreen(taskId: null),
          ),
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
