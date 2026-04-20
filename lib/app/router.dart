import 'package:dawnbreaker/ui/editor/widgets/editor_screen.dart';
import 'package:dawnbreaker/ui/home/widgets/home_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, _) => const HomeScreen()),
    GoRoute(
      path: '/editor',
      builder: (_, state) => EditorScreen(taskId: state.extra as int?),
    ),
  ],
);
