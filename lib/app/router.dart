import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/game/presentation/screens/journey_screen.dart';
import '../features/game/presentation/screens/missions_screen.dart';
import '../features/game/presentation/screens/profile_screen.dart';
import '../features/game/presentation/screens/shop_screen.dart';
import '../features/game/presentation/screens/training_screen.dart';
import '../features/game/presentation/screens/week_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/missoes',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        _branch('/missoes', const MissionsScreen()),
        _branch('/jornada', const JourneyScreen()),
        _branch('/semana', const WeekScreen()),
        _branch('/cursos', const TrainingScreen()),
        _branch('/loja', const ShopScreen()),
      ],
    ),
    GoRoute(path: '/perfil', builder: (context, state) => const ProfileScreen()),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => screen)],
    );

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Missões'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Jornada'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Semana'),
          NavigationDestination(icon: Icon(Icons.code), label: 'Cursos'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Loja'),
        ],
      ),
    );
  }
}
