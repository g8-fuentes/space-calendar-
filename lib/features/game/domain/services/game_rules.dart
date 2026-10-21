import '../../../../core/time/week_utils.dart';
import '../catalog/catalog.dart';
import '../catalog/schedule.dart';
import '../entities/game_state.dart';
import 'game_stats.dart';

/// Casos de uso do jogo. Funções puras: recebem o estado e devolvem
/// um novo estado, sem efeitos colaterais.
class GameRules {
  const GameRules._();

  static GameState toggleQuest(GameState s, String questId, String weekKey, int at) {
    final w = s.week(weekKey);
    final done = Map<String, int>.of(w.done);
    if (done.containsKey(questId)) {
      done.remove(questId);
    } else {
      done[questId] = at;
    }
    return _putWeek(s, weekKey, w.copyWith(done: done));
  }

  /// Marca as missões de hoje cujo horário já terminou.
  static GameState markPastToday(GameState s, DateTime now) {
    final key = weekKeyOf(now);
    final w = s.week(key);
    final done = Map<String, int>.of(w.done);
    final minute = minutesOfDay(now);
    for (final q in weeklySchedule[dayIndexOf(now)].quests) {
      if (q.endMinutes <= minute) done.putIfAbsent(q.id, () => now.millisecondsSinceEpoch);
    }
    return _putWeek(s, key, w.copyWith(done: done));
  }

  static GameState addLesson(GameState s, String courseId, DateTime now) {
    final p = s.course(courseId);
    if (p.completed) return s;
    return s.copyWith(
      courses: {...s.courses, courseId: CourseProgress(p.done + 1, p.total)},
      lessons: [...s.lessons, LessonLog(courseId, now.millisecondsSinceEpoch, weekKeyOf(now))],
    );
  }

  static GameState removeLesson(GameState s, String courseId) {
    final p = s.course(courseId);
    if (p.done <= 0) return s;
    final lessons = List<LessonLog>.of(s.lessons);
    final i = lessons.lastIndexWhere((l) => l.courseId == courseId);
    if (i >= 0) lessons.removeAt(i);
    return s.copyWith(
      courses: {...s.courses, courseId: CourseProgress(p.done - 1, p.total)},
      lessons: lessons,
    );
  }

  static GameState setCourseTotal(GameState s, String courseId, int total) {
    final t = total.clamp(1, 999).toInt();
    final p = s.course(courseId);
    return s.copyWith(courses: {
      ...s.courses,
      courseId: CourseProgress(p.done > t ? t : p.done, t),
    });
  }

  /// Abre o baú da semana no nível alcançado. Só abre com 100% na semana
  /// atual ou, em semanas passadas, com pelo menos Bronze.
  static GameState openChest(GameState s, String weekKey, String currentWeekKey) {
    final w = s.week(weekKey);
    if (w.chest != null) return s;
    final stats = weekStatsOf(s, weekKey);
    final tier = tierFor(stats.ratio);
    if (tier == null) return s;
    if (weekKey == currentWeekKey && stats.ratio < 1) return s;

    final boss = bossForWeek(weekKey, weekMaxXp);
    final beat = stats.xp >= boss.hp;
    String? item;
    if (tier.key != 'bronze') {
      final available = cosmeticCatalog.where((c) => !s.owned.contains(c.id)).toList();
      if (available.isNotEmpty) {
        item = available[stringHash('$weekKey#loot') % available.length].id;
      }
    }
    final loot = ChestLoot(
      tier: tier.key,
      coins: tier.coins + (beat ? bossBonusCoins : 0),
      xp: tier.xp + (beat ? bossBonusXp : 0),
      bossDefeated: beat,
      item: item,
    );
    final next = _putWeek(s, weekKey, w.copyWith(chest: loot));
    return item == null ? next : next.copyWith(owned: {...next.owned, item});
  }

  static GameState buyCosmetic(GameState s, Cosmetic c, int coins, int at) {
    if (s.owned.contains(c.id) || coins < c.price) return s;
    return s.copyWith(
      purchases: [...s.purchases, Purchase(c.id, c.name, c.price, at)],
      owned: {...s.owned, c.id},
      equipped: {...s.equipped, c.slot.name: c.id},
    );
  }

  static GameState toggleEquip(GameState s, Cosmetic c) {
    if (!s.owned.contains(c.id)) return s;
    final eq = Map<String, String>.of(s.equipped);
    if (eq[c.slot.name] == c.id) {
      eq.remove(c.slot.name);
    } else {
      eq[c.slot.name] = c.id;
    }
    return s.copyWith(equipped: eq);
  }

  static GameState buyUpgrade(GameState s, Upgrade u, int coins, int at) {
    final level = s.upgradeLevel(u.id);
    final cost = u.costFor(level);
    if (coins < cost) return s;
    return s.copyWith(
      purchases: [...s.purchases, Purchase('up-${u.id}', '${u.name} nível ${level + 1}', cost, at)],
      upgrades: {...s.upgrades, u.id: level + 1},
    );
  }

  static GameState redeemReward(GameState s, Reward r, int coins, int at) {
    if (coins < r.price) return s;
    return s.copyWith(purchases: [...s.purchases, Purchase(r.id, r.name, r.price, at)]);
  }

  static GameState addReward(GameState s, String name, int price, int at) {
    final clean = name.trim();
    if (clean.isEmpty) return s;
    return s.copyWith(rewards: [
      ...s.rewards,
      Reward('c$at', clean, price.clamp(10, 5000).toInt()),
    ]);
  }

  static GameState setSuitMode(GameState s, int mode, GameStats stats) {
    if (mode < 0 || mode >= suitModes.length) return s;
    if (!stats.modeUnlocked(suitModes[mode])) return s;
    return s.copyWith(suitMode: mode);
  }

  static GameState _putWeek(GameState s, String key, WeekRecord w) =>
      s.copyWith(weeks: {...s.weeks, key: w});
}

/// Acontecimentos que a interface celebra com um aviso.
sealed class GameEvent {
  const GameEvent();
}

class LevelUp extends GameEvent {
  const LevelUp(this.level);
  final int level;
}

class RankUp extends GameEvent {
  const RankUp(this.rank);
  final Rank rank;
}

class NewSuit extends GameEvent {
  const NewSuit(this.mk);
  final int mk;
}

class ModeUnlocked extends GameEvent {
  const ModeUnlocked(this.mode);
  final SuitMode mode;
}

class ArrivedAt extends GameEvent {
  const ArrivedAt(this.destinationIndex);
  final int destinationIndex;
}

class CourseCompleted extends GameEvent {
  const CourseCompleted(this.course);
  final Course course;
}

class ChestOpened extends GameEvent {
  const ChestOpened(this.loot);
  final ChestLoot loot;
}

/// Compara as estatísticas antes e depois de uma ação.
List<GameEvent> diffEvents(GameStats before, GameStats after, GameState prev, GameState next) {
  final events = <GameEvent>[];
  if (after.lv > before.lv) events.add(LevelUp(after.lv));
  if (after.rankIndex > before.rankIndex) events.add(RankUp(after.rank));
  if (after.suitMk > before.suitMk) events.add(NewSuit(after.suitMk));
  for (final m in suitModes) {
    if (m.id > 0 && after.modeUnlocked(m) && !before.modeUnlocked(m)) {
      events.add(ModeUnlocked(m));
    }
  }
  if (after.destinationIndex > before.destinationIndex) {
    events.add(ArrivedAt(after.destinationIndex));
  }
  for (final c in courseCatalog) {
    if (next.course(c.id).completed && !prev.course(c.id).completed) {
      events.add(CourseCompleted(c));
    }
  }
  return events;
}
