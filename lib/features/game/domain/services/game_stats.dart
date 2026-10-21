import 'dart:math' as math;

import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../catalog/catalog.dart';
import '../catalog/destinations.dart';
import '../entities/game_state.dart';

/// XP de uma missão: taxa da categoria por hora, entre meia hora e 4 horas.
int questXp(Mission m) {
  var dur = 1.0;
  final a = minutesOf(m.start), b = minutesOf(m.end);
  if (a != null && b != null) {
    dur = (b - a) / 60;
    if (dur <= 0) dur += 24;
  }
  final xp = (categoryOf(m.category).rate * math.max(.5, math.min(dur, 4))).round();
  return math.max(5, xp);
}

int questCoins(int xp) => math.max(1, (xp / 5).round());

String slotKey(Mission m, int day) => '${m.id}@$day';

/// Missões de um dia, em ordem de horário (sem horário primeiro).
List<Mission> daySlots(GameState s, int day) {
  final list = s.missions.where((m) => m.days.contains(day)).toList();
  list.sort((a, b) {
    final c = (minutesOf(a.start) ?? -1).compareTo(minutesOf(b.start) ?? -1);
    return c != 0 ? c : a.title.compareTo(b.title);
  });
  return list;
}

int totalSlots(GameState s) => s.missions.fold(0, (a, m) => a + m.days.length);

int dayDone(GameState s, WeekRecord w, int day) {
  var n = 0;
  for (final m in s.missions) {
    if (m.days.contains(day) && w.done.containsKey(slotKey(m, day))) n++;
  }
  return n;
}

class WeekStats {
  const WeekStats(this.done, this.xp, this.total);
  final int done;
  final int xp;
  final int total;
  double get ratio => total == 0 ? 0 : math.min(1, done / total);
}

WeekStats weekStatsOf(GameState s, String key) {
  final w = s.weeks[key];
  final tot = totalSlots(s);
  if (w == null) return WeekStats(0, 0, tot);
  var xp = 0;
  for (final r in w.done.values) {
    xp += r.xp;
  }
  return WeekStats(math.min(w.done.length, tot), xp, tot);
}

/// Dias já passados (desde o início do jogo) com menos da metade feita.
int weakDaysOf(GameState s, String key, DateTime now) {
  final w = s.weeks[key] ?? WeekRecord();
  final today = ymd(now);
  var n = 0;
  for (var di = 0; di < 7; di++) {
    final ds = ymd(dateOf(key, di));
    if (ds.compareTo(s.startDate) < 0 || ds.compareTo(today) >= 0) continue;
    final tot = daySlots(s, di).length;
    if (tot == 0) continue;
    if (dayDone(s, w, di) / tot < .5) n++;
  }
  return n;
}

class LevelInfo {
  const LevelInfo(this.level, this.into, this.need);
  final int level;
  final int into;
  final int need;
  double get ratio => need == 0 ? 0 : into / need;
}

/// Curva sem teto: cada nível pede 70 XP a mais que o anterior.
LevelInfo levelInfoFor(int xp) {
  var lv = 1, need = 120, acc = 0;
  while (xp >= acc + need) {
    acc += need;
    lv++;
    need = 120 + (lv - 1) * 70;
  }
  return LevelInfo(lv, xp - acc, need);
}

/// XP de um curso: aulas avulsas mais o XP das missões ligadas a ele.
int courseXpOf(GameState s, Course c) {
  var xp = c.lessons * lessonXp;
  for (final w in s.weeks.values) {
    for (final r in w.done.values) {
      if (r.courseId == c.id) xp += r.xp;
    }
  }
  return xp;
}

class Cefr {
  const Cefr(this.level, this.into, this.need, this.next);
  final String level;
  final int into;
  final int need;
  final String? next;
}

Cefr cefrOf(int xp) {
  var i = 0;
  for (var j = 0; j < cefrLevels.length; j++) {
    if (xp >= cefrLevels[j].$2) i = j;
  }
  final cur = cefrLevels[i];
  final nx = i + 1 < cefrLevels.length ? cefrLevels[i + 1] : null;
  return Cefr(cur.$1, xp - cur.$2, nx == null ? 0 : nx.$2 - cur.$2, nx?.$1);
}

/// Dias seguidos com pelo menos uma missão ligada ao idioma [courseId].
int languageStreak(GameState s, String courseId, DateTime now) {
  final days = <String>{};
  s.weeks.forEach((k, w) {
    for (final r in w.done.values) {
      if (r.courseId == courseId) days.add(ymd(dateOf(k, r.day)));
    }
  });
  var d = DateTime(now.year, now.month, now.day);
  if (!days.contains(ymd(d))) d = DateTime(d.year, d.month, d.day - 1);
  var streak = 0;
  while (days.contains(ymd(d))) {
    streak++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return streak;
}

/// Semanas seguidas (contando a atual) com 60% ou mais.
int weekStreak(GameState s, DateTime now) {
  var streak = 0;
  var monday = mondayOf(now);
  if (weekStatsOf(s, ymd(monday)).ratio >= .6) streak++;
  for (var i = 1; i < 300; i++) {
    monday = DateTime(monday.year, monday.month, monday.day - 7);
    if (weekStatsOf(s, ymd(monday)).ratio >= .6) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/// Números derivados do estado. Nada disso é salvo.
class GameStats {
  const GameStats({
    required this.xp,
    required this.coins,
    required this.level,
    required this.goldWeeks,
    required this.penalty,
    required this.weakDays,
    required this.coursesDone,
    required this.questsDone,
    required this.byCategory,
    required this.destinationIndex,
  });

  final int xp;
  final int coins;
  final LevelInfo level;
  final int goldWeeks;
  final int penalty;
  final int weakDays;
  final int coursesDone;
  final int questsDone;
  final Map<String, int> byCategory;
  final int destinationIndex;

  int get lv => level.level;
  int get rankIndex => rankIndexFor(lv);
  Rank get rank => rankAt(rankIndex);
  int get suitMk => suitMkFor(lv);
  Enemy get enemy => enemyFor(lv);
  Destination get destination => destinationAt(destinationIndex);
  Destination get nextDestination => destinationAt(destinationIndex + 1);
  bool modeUnlocked(SuitMode m) => m.unlocked(gold: goldWeeks, lv: lv);
}

GameStats computeStats(GameState s, DateTime now) {
  var xp = s.bonusXp, coins = 0, gold = 0, weak = 0, mxp = 0, mcoins = 0, done = 0;
  final cats = <String, int>{};
  s.weeks.forEach((k, w) {
    for (final r in w.done.values) {
      mxp += r.xp;
      mcoins += r.coins;
      done++;
      cats[r.category] = (cats[r.category] ?? 0) + 1;
    }
    final chest = w.chest;
    if (chest != null) {
      coins += chest.coins;
      xp += chest.xp;
      if (chest.tier == 'ouro') gold++;
    }
    weak += weakDaysOf(s, k, now);
  });
  xp += (mxp * (1 + .03 * s.upgradeLevel('antena'))).round();
  coins += (mcoins * (1 + .05 * s.upgradeLevel('motor'))).round();
  var lessons = 0, coursesDone = 0;
  for (final c in s.courses) {
    lessons += c.lessons;
    if (c.finished) {
      coursesDone++;
      xp += courseXp;
      coins += courseCoins;
    }
  }
  xp += lessons * lessonXp;
  coins += lessons * lessonCoins;
  final penalty = math.max(0, weak - s.shields) * weakDayPenalty;
  coins -= penalty;
  coins -= s.purchases.fold(0, (a, p) => a + p.price);
  return GameStats(
    xp: xp,
    coins: coins,
    level: levelInfoFor(xp),
    goldWeeks: gold,
    penalty: penalty,
    weakDays: weak,
    coursesDone: coursesDone,
    questsDone: done,
    byCategory: cats,
    destinationIndex: destinationIndexFor(xp),
  );
}

class Achievement {
  const Achievement(this.icon, this.name, this.description, this.unlocked);
  final String icon;
  final String name;
  final String description;
  final bool unlocked;
}

List<Achievement> achievementsOf(GameState s, GameStats t, DateTime now) {
  var maxLang = 0;
  for (final c in s.courses.where((c) => c.isLanguage)) {
    maxLang = math.max(maxLang, languageStreak(s, c.id, now));
  }
  final chests = s.weeks.values.where((w) => w.chest != null).length;
  return [
    Achievement('1ª', 'Primeira missão', 'Conclua uma missão.', t.questsDone >= 1),
    Achievement('10', 'Dez missões', 'Conclua 10 missões.', t.questsDone >= 10),
    Achievement('100', 'Cem missões', 'Conclua 100 missões.', t.questsDone >= 100),
    Achievement('500', 'Lenda da rotina', 'Conclua 500 missões.', t.questsDone >= 500),
    Achievement('BÚ', 'Primeiro baú', 'Abra um baú semanal.', chests >= 1),
    Achievement('AU', 'Semana de ouro', 'Feche uma semana com 100%.', t.goldWeeks >= 1),
    Achievement('L5', 'Nível 5', 'Chegue ao nível 5.', t.lv >= 5),
    Achievement('L10', 'Nível 10', 'Chegue ao nível 10 e enfrente o primeiro chefe.', t.lv >= 10),
    Achievement('L25', 'Nível 25', 'Chegue ao nível 25.', t.lv >= 25),
    Achievement('CR', 'Formatura', 'Conclua um curso.', t.coursesDone >= 1),
    Achievement('7d', 'Poliglota em treino', '7 dias seguidos em um idioma.', maxLang >= 7),
    Achievement('30d', 'Fluência em órbita', '30 dias seguidos em um idioma.', maxLang >= 30),
    Achievement('LJ', 'Primeira compra', 'Compre algo na loja.', s.purchases.isNotEmpty),
    Achievement('3s', 'Três semanas boas', '3 semanas seguidas com 60% ou mais.', weekStreak(s, now) >= 3),
  ];
}
