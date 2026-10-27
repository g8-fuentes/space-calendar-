import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound/music.dart';
import '../core/sound/sfx.dart';
import '../features/game/presentation/controllers/game_providers.dart';
import '../features/game/presentation/screens/character_screen.dart';
import '../features/game/presentation/screens/explore_screen.dart';
import '../features/game/presentation/screens/intro_screen.dart';
import '../features/game/presentation/screens/map_screen.dart';
import '../features/game/presentation/screens/settings_screen.dart';
import '../features/game/presentation/screens/week_screen.dart';
import '../features/game/presentation/widgets/ui.dart';
import 'theme/kanagawa.dart';

class RotinaQuestApp extends StatefulWidget {
  const RotinaQuestApp({super.key});

  @override
  State<RotinaQuestApp> createState() => _RotinaQuestAppState();
}

class _RotinaQuestAppState extends State<RotinaQuestApp> {
  // A música só toca com o app na tela.
  late final _lifecycle = AppLifecycleListener(
    onStateChange: (s) => MusicBox.instance.setForeground(s == AppLifecycleState.resumed),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Routine',
      debugShowCheckedModeBanner: false,
      theme: buildKanagawaTheme(),
      home: const _Root(),
    );
  }
}

/// Tela inicial na primeira vez (ou depois de zerar); depois, o jogo.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(gameControllerProvider.select((s) => s.onboarded));
    return NoticeListener(child: onboarded ? const GameShell() : const IntroScreen());
  }
}

final shellTabProvider = StateProvider<int>((ref) => 0);

class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  static const _tabs = [
    (Icons.rocket_launch_outlined, 'EXPLORAR'),
    (Icons.bolt, 'PERSONAGEM'),
    (Icons.public, 'MAPA'),
    (Icons.calendar_view_week_outlined, 'SEMANA'),
    (Icons.tune, 'AJUSTES'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(gameControllerProvider).alerts) ref.read(missionAlertsProvider).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i = ref.watch(shellTabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (i) {
          0 => const ExploreScreen(),
          1 => const CharacterScreen(),
          2 => const MapScreen(),
          3 => const WeekScreen(),
          _ => const SettingsScreen(),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (n) {
          if (n == i) return;
          Sfx.tab.play();
          ref.read(shellTabProvider.notifier).state = n;
        },
        destinations: [
          for (final (icon, label) in _tabs)
            NavigationDestination(
              icon: Icon(icon, color: Kanagawa.springViolet1),
              selectedIcon: Icon(icon, color: Kanagawa.carpYellow),
              label: label,
            ),
        ],
      ),
    );
  }
}
