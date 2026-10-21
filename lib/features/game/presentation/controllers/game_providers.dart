import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sound/sfx.dart';
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

  @override
  GameState build() {
    final s = ref.read(initialGameStateProvider);
    SoundBoard.instance.enabled = s.sound;
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
    unawaited(ref.read(gameRepositoryProvider).save(fresh));
  }
}
