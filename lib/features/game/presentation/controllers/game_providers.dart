import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/mission_alerts.dart';
import '../../../../core/sound/music.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/week_utils.dart';
import '../../../../core/weather/weather.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';

/// Injetados em `main()` com `ProviderScope(overrides: ...)`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
final gameRepositoryProvider = Provider<GameRepository>((ref) => throw UnimplementedError('override em main'));
final initialGameStateProvider = Provider<GameState>((ref) => throw UnimplementedError('override em main'));
final missionAlertsProvider = Provider<MissionAlerts>((ref) => const NoMissionAlerts());
final weatherSourceProvider = Provider<Future<WeatherNow?> Function()>((ref) => fetchBauruWeather);

/// Relógio da tela: atualiza a cada 15 segundos.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock.now());
  final timer = Timer.periodic(const Duration(seconds: 15), (_) => controller.add(clock.now()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

DateTime currentTime(Ref<Object?> ref) => ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();

/// Tempo em Bauru, atualizado a cada 20 minutos.
final weatherProvider = StreamProvider<WeatherNow?>((ref) {
  final fetch = ref.watch(weatherSourceProvider);
  final controller = StreamController<WeatherNow?>();
  Future<void> load() async {
    final w = await fetch();
    if (!controller.isClosed && w != null) controller.add(w);
  }

  unawaited(load());
  final timer = Timer.periodic(const Duration(minutes: 20), (_) => load());
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

final gameControllerProvider = NotifierProvider<GameController, GameState>(GameController.new);

final statsProvider = Provider<GameStats>((ref) => computeStats(ref.watch(gameControllerProvider), currentTime(ref)));

/// Missão concluída, para a cena comemorar.
class BurstEvent {
  const BurstEvent(this.serial);
  final int serial;
}

final burstProvider = StateProvider<BurstEvent?>((ref) => null);

/// Fila de avisos grandes (lugar novo, importação...).
final noticesProvider = StateProvider<List<Notice>>((ref) => const []);

/// Dia selecionado na lista de missões.
final selectedDayProvider = StateProvider<int>((ref) => dayIndexOf(ref.read(clockProvider).now()));

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
                    'Marque no app quando concluir para seguir na jornada.',
              ),
    ];

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
    if (s.lastPlace < 0 || s.lastForm < 0) {
      final t = computeStats(s, ref.read(clockProvider).now());
      if (s.lastPlace < 0) s.lastPlace = t.placeIndex;
      if (s.lastForm < 0) s.lastForm = t.formIndex;
    }
    SoundBoard.instance.enabled = s.sound;
    MusicBox.instance.enabled = s.music;
    ref.onDispose(() => _alertTimer?.cancel());
    _syncAlerts(s);
    return s;
  }

  DateTime get now => ref.read(clockProvider).now();

  /// Aplica [change] numa cópia do estado.
  T apply<T>(T Function(GameState s) change) {
    final next = state.copy();
    final result = change(next);
    final notices = GameRules.progressNotices(next, computeStats(next, now));
    state = next;
    SoundBoard.instance.enabled = next.sound;
    MusicBox.instance.enabled = next.music;
    _syncAlerts(next);
    unawaited(ref.read(gameRepositoryProvider).save(next));
    if (notices.isNotEmpty) notify(notices);
    return result;
  }

  void notify(List<Notice> notices) {
    final q = ref.read(noticesProvider.notifier);
    q.state = [...q.state, ...notices];
  }

  void celebrate() => ref.read(burstProvider.notifier).state = BurstEvent(++_serial);

  Future<void> reset() async {
    final keep = state;
    await ref.read(gameRepositoryProvider).clear();
    final fresh = GameState.initial(ymd(now))
      ..sound = keep.sound
      ..music = keep.music
      ..alerts = keep.alerts
      ..lastPlace = 0
      ..lastForm = 0;
    state = fresh;
    _syncAlerts(fresh);
    unawaited(ref.read(gameRepositoryProvider).save(fresh));
  }
}
