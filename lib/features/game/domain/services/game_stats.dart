import 'dart:math' as math;

import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../catalog/places.dart';
import '../entities/game_state.dart';

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
  const WeekStats(this.done, this.total);
  final int done;
  final int total;
  double get ratio => total == 0 ? 0 : math.min(1, done / total);
}

WeekStats weekStatsOf(GameState s, String key) {
  final w = s.weeks[key];
  return WeekStats(w == null ? 0 : math.min(w.done.length, math.max(totalSlots(s), w.done.length)), totalSlots(s));
}

/// Números derivados do estado. Nada disso é salvo.
class GameStats {
  const GameStats({required this.missionsDone, required this.placeIndex, required this.doneToday, required this.totalToday});

  /// Missões concluídas desde o começo.
  final int missionsDone;
  final int placeIndex;
  final int doneToday;
  final int totalToday;

  Place get place => placeAt(placeIndex);
  Place get next => placeAt(placeIndex + 1);

  /// Missões que faltam para o próximo lugar.
  int get missing => next.missionsRequired - missionsDone;

  /// Progresso (0 a 1) entre o lugar atual e o próximo.
  double get progress {
    final span = next.missionsRequired - place.missionsRequired;
    return span <= 0 ? 1 : ((missionsDone - place.missionsRequired) / span).clamp(0.0, 1.0);
  }
}

GameStats computeStats(GameState s, DateTime now) {
  var done = 0;
  for (final w in s.weeks.values) {
    done += w.done.length;
  }
  final today = dayIndexOf(now);
  final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
  return GameStats(
    missionsDone: done,
    placeIndex: placeIndexFor(done),
    doneToday: dayDone(s, w, today),
    totalToday: daySlots(s, today).length,
  );
}
