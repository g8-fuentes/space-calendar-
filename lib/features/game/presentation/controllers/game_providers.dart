import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/mission_alerts.dart';
import '../../../../core/sound/music.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';

/// Injetados em `main()` com `ProviderScope(overrides: ...)`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
final gameRepositoryProvider = Provider<GameRepository>((ref) => throw UnimplementedError('override em main'));
final initialGameStateProvider = Provider<GameState>((ref) => throw UnimplementedError('override em main'));
final missionAlertsProvider = Provider<MissionAlerts>((ref) => const NoMissionAlerts());

/// Um aviso por missão com horário, em cada dia em que ela acontece.
List<Alert> alertsFor(GameState s) => [
      if (s.alerts)
        for (final m in s.missions)
          if (minutesOf(m.start) != null)
            for (final d in m.days)
              Alert(
                key: '${m.id}@$d',
                day: d,
                minutes: minutesOf(m.start)!,
                title: '🚀 ${m.title}',
                body: 'Sua missão começou${m.end.isEmpty ? '' : ' (${m.start} às ${m.end})'}. '
                    'Conclua e marque no app para ganhar +${questXp(m)} XP.',
              ),
    ];

/// Relógio que atualiza a tela a cada 30 segundos (missão "agora").
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock.now());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => controller.add(clock.now()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

DateTime currentTime(Ref<Object?> ref) => ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();

final gameControllerProvider = NotifierProvider<GameController, GameState>(GameController.new);

final statsProvider = Provider<GameStats>((ref) => computeStats(ref.watch(gameControllerProvider), currentTime(ref)));

/// XP ganho, para a cena comemorar.
class BurstEvent {
  const BurstEvent(this.xp, this.serial);
  final int xp;
  final int serial;
}

final burstProvider = StateProvider<BurstEvent?>((ref) => null);

/// Fila de avisos grandes (level up, destino, baú...).
final noticesProvider = StateProvider<List<Notice>>((ref) => const []);

/// Dia selecionado na lista de missões.
final selectedDayProvider = StateProvider<int>((ref) => dayIndexOf(ref.read(clockProvider).now()));

/// Orquestra as regras: copia o estado, aplica a mudança, salva e
/// publica os avisos de progresso.
class GameController extends Notifier<GameState> {
  int _serial = 0;
  String? _alertSig;
  Timer? _alertTimer;

  /// Reagenda as notificações só quando missões ou a opção mudam.
  void _syncAlerts(GameState s) {
    final list = alertsFor(s);
    final sig = list.map((a) => '${a.key}|${a.minutes}|${a.title}|${a.body}').join(';');
    if (sig == _alertSig) return;
    _alertSig = sig;
    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(milliseconds: 800), () => ref.read(missionAlertsProvider).replaceAll(list));
  }

  @override
  GameState build() {
    final s = ref.read(initialGameStateProvider);
    SoundBoard.instance.enabled = s.sound;
    MusicBox.instance.enabled = s.music;
    ref.onDispose(() => _alertTimer?.cancel());
    _syncAlerts(s);
    return s;
  }

  DateTime get now => ref.read(clockProvider).now();

  /// Aplica [change] numa cópia do estado. [burst] faz o astronauta pular.
  T apply<T>(T Function(GameState s) change, {int? burst}) {
    final next = state.copy();
    final result = change(next);
    final notices = GameRules.progressNotices(next, computeStats(next, now));
    state = next;
    SoundBoard.instance.enabled = next.sound;
    MusicBox.instance.enabled = next.music;
    _syncAlerts(next);
    unawaited(ref.read(gameRepositoryProvider).save(next));
    if (burst != null) ref.read(burstProvider.notifier).state = BurstEvent(burst, ++_serial);
    if (notices.isNotEmpty) notify(notices);
    return result;
  }

  void notify(List<Notice> notices) {
    final q = ref.read(noticesProvider.notifier);
    q.state = [...q.state, ...notices];
  }

  void celebrate(int xp) => ref.read(burstProvider.notifier).state = BurstEvent(xp, ++_serial);

  Future<void> reset() async {
    final sound = state.sound;
    await ref.read(gameRepositoryProvider).clear();
    final fresh = GameState.initial(ymd(now))..sound = sound;
    state = fresh;
    _syncAlerts(fresh);
    unawaited(ref.read(gameRepositoryProvider).save(fresh));
  }
}
