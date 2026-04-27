import 'package:dawnbreaker/ui/app_detail/widgets/app_detail_screen.dart';
import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, _) => const HomeScreen()),
    GoRoute(
      path: '/app-detail',
      builder: (_, state) => AppDetailScreen(taskId: state.extra as int),
    ),
    GoRoute(
      path: '/editor',
      builder: (_, state) => EditorScreen(taskId: state.extra as int?),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, state) => const OnboardingScreen(),
    ),
  ],
);
