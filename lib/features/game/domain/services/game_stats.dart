import 'dart:math' as math;

import '../../../../core/time/week_utils.dart';
import '../catalog/catalog.dart';
import '../catalog/destinations.dart';
import '../catalog/schedule.dart';
import '../entities/game_state.dart';
import '../entities/quest.dart';

class LevelInfo {
  const LevelInfo(this.level, this.intoLevel, this.needed);
  final int level;
  final int intoLevel;
  final int needed;

  double get ratio => needed == 0 ? 0 : intoLevel / needed;
}

/// Curva de nível sem teto: cada nível pede 70 XP a mais que o anterior.
LevelInfo levelInfoFor(int xp) {
  var level = 1;
  var need = 120;
  var acc = 0;
  while (xp >= acc + need) {
    acc += need;
    level++;
    need = 120 + (level - 1) * 70;
  }
  return LevelInfo(level, xp - acc, need);
}

class WeekStats {
  const WeekStats(this.done, this.xp);
  final int done;
  final int xp;

  double get ratio => allQuests.isEmpty ? 0 : done / allQuests.length;
}

WeekStats weekStatsOf(GameState s, String weekKey) {
  final w = s.week(weekKey);
  var n = 0;
  var xp = 0;
  for (final q in allQuests) {
    if (w.done.containsKey(q.id)) {
      n++;
      xp += q.xp;
    }
  }
  return WeekStats(n, xp);
}

/// Dias já passados (desde o início do jogo) com menos de 50% cumprido.
List<String> weakDaysOf(GameState s, String weekKey, DateTime now) {
  final w = s.week(weekKey);
  final today = ymd(now);
  final result = <String>[];
  for (var di = 0; di < weeklySchedule.length; di++) {
    final date = ymd(dateOf(weekKey, di));
    if (date.compareTo(s.startDate) < 0 || date.compareTo(today) >= 0) continue;
    final day = weeklySchedule[di];
    final done = day.quests.where((q) => w.done.containsKey(q.id)).length;
    if (done / day.quests.length < 0.5) result.add(day.name);
  }
  return result;
}

/// Números derivados do estado. Nada disso é salvo: é sempre
/// recalculado, então nunca fica inconsistente.
class GameStats {
  const GameStats({
    required this.xp,
    required this.coins,
    required this.level,
    required this.goldWeeks,
    required this.goodWeeks,
    required this.penalty,
    required this.coursesDone,
    required this.questsDone,
    required this.byTag,
    required this.byCategory,
    required this.destinationIndex,
  });

  final int xp;
  final int coins;
  final LevelInfo level;
  final int goldWeeks;
  final int goodWeeks;
  final int penalty;
  final int coursesDone;
  final int questsDone;
  final Map<String, int> byTag;
  final Map<QuestCategory, int> byCategory;
  final int destinationIndex;

  int get lv => level.level;
  int get rankIndex => rankIndexFor(lv);
  Rank get rank => rankAt(rankIndex);
  int get suitMk => suitMkFor(lv);
  Destination get destination => destinationAt(destinationIndex);
  Destination get nextDestination => destinationAt(destinationIndex + 1);
  int tag(String t) => byTag[t] ?? 0;

  bool modeUnlocked(SuitMode m) => m.unlocked(gold: goldWeeks, lv: lv);
}

GameStats computeStats(GameState s, DateTime now) {
  var missionXp = 0;
  var missionCoins = 0;
  var xp = 0;
  var coins = 0;
  var gold = 0;
  var good = 0;
  var penalty = 0;
  final byTag = <String, int>{};
  final byCat = <QuestCategory, int>{};

  s.weeks.forEach((key, w) {
    for (final q in allQuests) {
      if (!w.done.containsKey(q.id)) continue;
      missionXp += q.xp;
      missionCoins += q.coins;
      byCat[q.category] = (byCat[q.category] ?? 0) + 1;
      final t = q.tag;
      if (t != null) byTag[t] = (byTag[t] ?? 0) + 1;
    }
    if (weekStatsOf(s, key).ratio >= 0.6) good++;
    final chest = w.chest;
    if (chest != null) {
      coins += chest.coins;
      xp += chest.xp;
      if (chest.tier == 'ouro') gold++;
    }
    penalty += weakDaysOf(s, key, now).length * weakDayPenalty;
  });

  xp += (missionXp * (1 + 0.03 * s.upgradeLevel('antena'))).round();
  coins += (missionCoins * (1 + 0.05 * s.upgradeLevel('motor'))).round();
  xp += s.lessons.length * lessonXp;
  coins += s.lessons.length * lessonCoins;

  var coursesDone = 0;
  for (final c in courseCatalog) {
    if (s.course(c.id).completed) {
      coursesDone++;
      xp += courseXp;
      coins += courseCoins;
    }
  }
  coins -= penalty;
  coins -= s.purchases.fold(0, (sum, p) => sum + p.price);

  final level = levelInfoFor(xp);
  return GameStats(
    xp: xp,
    coins: coins,
    level: level,
    goldWeeks: gold,
    goodWeeks: good,
    penalty: penalty,
    coursesDone: coursesDone,
    questsDone: byCat.values.fold(0, (a, b) => a + b),
    byTag: byTag,
    byCategory: byCat,
    destinationIndex: destinationIndexFor(xp),
  );
}

/// Semanas seguidas (contando a atual) com 60% ou mais.
int weekStreak(GameState s, DateTime now) {
  var streak = 0;
  var monday = mondayOf(now);
  if (weekStatsOf(s, ymd(monday)).ratio >= 0.6) streak++;
  for (var i = 0; i < 520; i++) {
    monday = DateTime(monday.year, monday.month, monday.day - 7);
    if (weekStatsOf(s, ymd(monday)).ratio >= 0.6) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/// Dias seguidos com pelo menos uma missão do idioma [tag].
int languageStreak(GameState s, String tag, DateTime now) {
  bool doneOn(DateTime d) {
    final w = s.weeks[weekKeyOf(d)];
    if (w == null) return false;
    return weeklySchedule[dayIndexOf(d)]
        .quests
        .any((q) => q.tag == tag && w.done.containsKey(q.id));
  }

  var day = DateTime(now.year, now.month, now.day);
  if (!doneOn(day)) day = DateTime(day.year, day.month, day.day - 1);
  var streak = 0;
  for (var i = 0; i < 3650 && doneOn(day); i++) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Medalha sem fim: cada nível dobra a meta.
class MedalTier {
  const MedalTier(this.tier, this.goal, this.previous);
  final int tier;
  final int goal;
  final int previous;

  double progress(int value) =>
      ((value - previous) / math.max(1, goal - previous)).clamp(0, 1).toDouble();
}

MedalTier medalTierFor(int base, int value) {
  var tier = 0;
  var goal = base;
  while (value >= goal) {
    tier++;
    goal *= 2;
  }
  return MedalTier(tier, goal, tier == 0 ? 0 : goal ~/ 2);
}
