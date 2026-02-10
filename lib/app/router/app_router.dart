import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/codex/presentation/codex_screen.dart';
import '../../features/dungeon/presentation/dungeon_screen.dart';
import '../../features/home/presentation/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <GoRoute>[
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/dungeon',
      builder: (context, state) => const DungeonScreen(),
    ),
    GoRoute(path: '/codex', builder: (context, state) => const CodexScreen()),
  ],
);
