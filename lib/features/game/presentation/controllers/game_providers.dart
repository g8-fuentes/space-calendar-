import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';

/// Injetados em `main()` com `ProviderScope(overrides: ...)`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
final gameRepositoryProvider =
    Provider<GameRepository>((ref) => throw UnimplementedError('override em main'));
final initialGameStateProvider =
    Provider<GameState>((ref) => throw UnimplementedError('override em main'));

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

DateTime _now(Ref<Object?> ref) => ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();

final gameControllerProvider =
    NotifierProvider<GameController, GameState>(GameController.new);

final statsProvider = Provider<GameStats>((ref) {
  return computeStats(ref.watch(gameControllerProvider), _now(ref));
});

/// Aviso visual de XP ganho, consumido pela cena.
class BurstEvent {
  const BurstEvent(this.xp, this.serial);
  final int xp;
  final int serial;
}

final burstProvider = StateProvider<BurstEvent?>((ref) => null);

/// Orquestra os casos de uso, salva o estado e devolve os eventos
/// que a interface deve celebrar.
class GameController extends Notifier<GameState> {
  int _serial = 0;

  @override
  GameState build() => ref.read(initialGameStateProvider);

  DateTime get _clockNow => ref.read(clockProvider).now();

  List<GameEvent> _apply(GameState Function(GameState s, GameStats stats) change, {int burstXp = 0}) {
    final prev = state;
    final now = _clockNow;
    final before = computeStats(prev, now);
    final next = change(prev, before);
    if (identical(next, prev)) return const [];
    state = next;
    unawaited(ref.read(gameRepositoryProvider).save(next));
    final after = computeStats(next, now);
    if (burstXp > 0 || after.xp > before.xp) {
      ref.read(burstProvider.notifier).state =
          BurstEvent(burstXp > 0 ? burstXp : after.xp - before.xp, ++_serial);
    }
    return diffEvents(before, after, prev, next);
  }

  /// Retorna true se a missão foi marcada (false se foi desmarcada).
  (bool, List<GameEvent>) toggleQuest(String questId) {
    final now = _clockNow;
    final key = weekKeyOf(now);
    final wasDone = state.week(key).done.containsKey(questId);
    final events = _apply((s, _) => GameRules.toggleQuest(s, questId, key, now.millisecondsSinceEpoch));
    return (!wasDone, events);
  }

  List<GameEvent> markPastToday() => _apply((s, _) => GameRules.markPastToday(s, _clockNow));

  List<GameEvent> addLesson(String courseId) =>
      _apply((s, _) => GameRules.addLesson(s, courseId, _clockNow), burstXp: lessonXp);

  List<GameEvent> removeLesson(String courseId) => _apply((s, _) => GameRules.removeLesson(s, courseId));

  void setCourseTotal(String courseId, int total) =>
      _apply((s, _) => GameRules.setCourseTotal(s, courseId, total));

  List<GameEvent> openChest(String weekKey) {
    final events = _apply((s, _) => GameRules.openChest(s, weekKey, weekKeyOf(_clockNow)));
    final loot = state.week(weekKey).chest;
    return [if (loot != null) ChestOpened(loot), ...events];
  }

  void buyCosmetic(Cosmetic c) => _apply(
      (s, stats) => GameRules.buyCosmetic(s, c, stats.coins, _clockNow.millisecondsSinceEpoch));

  void toggleEquip(Cosmetic c) => _apply((s, _) => GameRules.toggleEquip(s, c));

  void buyUpgrade(Upgrade u) => _apply(
      (s, stats) => GameRules.buyUpgrade(s, u, stats.coins, _clockNow.millisecondsSinceEpoch));

  void redeemReward(Reward r) => _apply(
      (s, stats) => GameRules.redeemReward(s, r, stats.coins, _clockNow.millisecondsSinceEpoch));

  void addReward(String name, int price) =>
      _apply((s, _) => GameRules.addReward(s, name, price, _clockNow.millisecondsSinceEpoch));

  void setSuitMode(int mode) => _apply((s, stats) => GameRules.setSuitMode(s, mode, stats));

  Future<void> reset() async {
    await ref.read(gameRepositoryProvider).clear();
    state = GameState.initial(ymd(_clockNow));
  }
}
