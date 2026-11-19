import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound/music.dart';
import '../core/sound/sfx.dart';
import '../features/game/presentation/controllers/game_providers.dart';
import '../features/game/presentation/controllers/sync_controller.dart';
import '../features/game/presentation/screens/character_screen.dart';
import '../features/game/presentation/screens/explore_screen.dart';
import '../features/game/presentation/screens/intro_screen.dart';
import '../features/game/presentation/screens/settings_screen.dart';
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
    return Consumer(builder: (context, ref, _) {
      // O tema vem do estado salvo; trocar reconstrói todas as telas.
      final light = ref.watch(gameControllerProvider.select((s) => s.light));
      Kanagawa.light = light;
      return MaterialApp(
        title: 'Dev Routine',
        debugShowCheckedModeBanner: false,
        theme: buildKanagawaTheme(),
        home: KeyedSubtree(key: ValueKey(light), child: const _Root()),
        builder: (context, child) => _WideFrame(child: child!),
      );
    });
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
    (Icons.terminal, 'EXPLORAR'),
    (Icons.bolt, 'PERSONAGEM'),
    (Icons.tune, 'AJUSTES'),
  ];

  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    // Ao voltar para o app: avisos da semana nova (destino novo na segunda).
    _life = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(gameControllerProvider).alerts) ref.read(missionAlertsProvider).requestPermission();
      _refresh();
    });
  }

  void _refresh() {
    if (!mounted) return;
    ref.read(gameControllerProvider.notifier).apply((_) {});
    // Traz o que mudou nos outros aparelhos.
    ref.read(syncProvider.notifier).syncNow();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
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

/// No computador o app fica numa coluna de celular no meio da tela. No
/// navegador, o primeiro toque também libera a música.
class _WideFrame extends StatelessWidget {
  const _WideFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget app = child;
    if (kIsWeb) {
      app = Listener(onPointerDown: (_) => MusicBox.instance.retryAfterGesture(), child: app);
    }
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 600) return app;
    return ColoredBox(
      color: Kanagawa.sumiInk0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: Size(520, MediaQuery.sizeOf(context).height)),
            child: ClipRect(child: app),
          ),
        ),
      ),
    );
  }
}
