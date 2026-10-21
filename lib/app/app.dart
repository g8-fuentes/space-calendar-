import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound/music.dart';
import '../core/sound/sfx.dart';
import '../features/game/presentation/controllers/game_providers.dart';
import '../features/game/presentation/controllers/import_flow.dart';
import '../features/game/presentation/screens/courses_screen.dart';
import '../features/game/presentation/screens/intro_screen.dart';
import '../features/game/presentation/screens/missions_screen.dart';
import '../features/game/presentation/screens/more_screen.dart';
import '../features/game/presentation/screens/shop_screen.dart';
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
      title: 'Rotina Quest',
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
  @override
  void initState() {
    super.initState();
    // Sincroniza o Google Agenda em silêncio ao abrir (no máximo a cada 15 min).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(gameControllerProvider);
      if (s.alerts) ref.read(missionAlertsProvider).requestPermission();
      final now = ref.read(gameControllerProvider.notifier).now.millisecondsSinceEpoch;
      if (s.calendarUrl != null && (s.lastSync == null || now - s.lastSync! > 15 * 60 * 1000)) {
        syncGoogleCalendar(null, ref, quiet: true);
      }
    });
  }

  static const _tabs = [
    (Icons.rocket_launch_outlined, 'MISSÕES'),
    (Icons.school_outlined, 'CURSOS'),
    (Icons.storefront_outlined, 'LOJA'),
    (Icons.inventory_2_outlined, 'SEMANA'),
    (Icons.public, 'MAIS'),
  ];

  @override
  Widget build(BuildContext context) {
    final i = ref.watch(shellTabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (i) {
          0 => const MissionsScreen(),
          1 => const CoursesScreen(),
          2 => const ShopScreen(),
          3 => const WeekScreen(),
          _ => const MoreScreen(),
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
