import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_screen.dart';
import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
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
          builder: (_, state) =>
              EditorScreen(taskId: int.parse(state.pathParameters['taskId']!)),
        ),
      ],
    ),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
  ],
);
