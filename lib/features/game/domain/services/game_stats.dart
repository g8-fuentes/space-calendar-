import 'dart:math' as math;

import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../catalog/catalog.dart';
import '../catalog/places.dart';
import '../catalog/transformations.dart';
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

/// Duração da missão em minutos (null sem horário).
int? missionMinutes(Mission m) {
  final a = minutesOf(m.start), b = minutesOf(m.end);
  if (a == null || b == null) return null;
  final d = b - a;
  return d <= 0 ? d + 1440 : d;
}

/// Pontos de atributo de uma missão concluída: 1 a cada 10 minutos,
/// de 3 a 24.
int pointsFor(int? minutes) => ((minutes ?? 30) / 10).round().clamp(3, 24);

/// Números derivados do estado. Nada disso é salvo.
class GameStats {
  const GameStats({
    required this.missionsDone,
    required this.placeIndex,
    required this.doneToday,
    required this.totalToday,
    required this.attributes,
    this.active = const {},
    this.weekKey = '',
    this.weekDone = 0,
    this.weekGoal = 1,
  });

  /// Missões concluídas desde o começo.
  final int missionsDone;
  final int placeIndex;
  final int doneToday;
  final int totalToday;

  /// Pontos por categoria (Vitalidade, Força...).
  final Map<String, int> attributes;

  /// Categorias das missões da agenda e as que já ganharam pontos.
  final Set<String> active;

  /// Semana atual (chave da segunda-feira).
  final String weekKey;

  /// Missões concluídas nesta semana e a meta que explora o destino.
  final int weekDone, weekGoal;

  int get power => attributes.values.fold(0, (a, b) => a + b);
  int get formIndex => transformationIndexFor(power);
  Transformation get form => transformationAt(formIndex);
  Transformation get nextForm => transformationAt(formIndex + 1);

  /// Pontos que faltam para a próxima transformação.
  int get powerMissing => nextForm.power - power;

  double get formProgress {
    final span = nextForm.power - form.power;
    return span <= 0 ? 1 : ((power - form.power) / span).clamp(0.0, 1.0);
  }

  /// Atributos que existem nas missões da agenda (ou que já têm pontos),
  /// na ordem do catálogo.
  List<Category> get shown => [
        for (final c in categories)
          if (active.contains(c.key)) c
      ];

  /// Atributo com mais pontos (null se ainda não tem nenhum).
  Category? get best {
    String? k;
    for (final e in attributes.entries) {
      if (e.value > 0 && (k == null || e.value > attributes[k]!)) k = e.key;
    }
    return k == null ? null : categoryOf(k);
  }

  /// Destino desta semana e o da próxima.
  Place get place => placeAt(placeIndex);
  Place get next => placeAt(placeIndex + 1);

  /// Meta da semana cumprida: na segunda-feira o dev parte para [next].
  bool get explored => weekDone >= weekGoal;

  /// Missões que faltam nesta semana para explorar o destino.
  int get missing => math.max(0, weekGoal - weekDone);

  /// Exploração do destino desta semana (0 a 1).
  double get progress => (weekDone / weekGoal).clamp(0.0, 1.0);
}

GameStats computeStats(GameState s, DateTime now) {
  var done = 0;
  final byId = {for (final m in s.missions) m.id: m};
  final attrs = {for (final c in categories) c.key: 0};
  for (final w in s.weeks.values) {
    done += w.done.length;
    for (final e in w.done.entries) {
      final r = e.value;
      final m = byId[e.key.split('@').first];
      final cat = r.category ?? m?.category ?? guessCategory(r.title);
      final pts = pointsFor(r.minutes ?? (m == null ? null : missionMinutes(m)));
      attrs[cat] = (attrs[cat] ?? 0) + pts;
    }
  }
  final today = dayIndexOf(now);
  final key = weekKeyOf(now);
  final w = s.weeks[key] ?? WeekRecord();
  return GameStats(
    missionsDone: done,
    // Um destino novo a cada semana já explorada (as chaves aaaa-mm-dd
    // ficam em ordem de data).
    placeIndex: s.explored.where((k) => k.compareTo(key) < 0).length,
    weekKey: key,
    weekDone: w.done.length,
    weekGoal: s.weeklyGoal,
    doneToday: dayDone(s, w, today),
    totalToday: daySlots(s, today).length,
    attributes: attrs,
    active: {
      for (final m in s.missions) m.category,
      for (final e in attrs.entries)
        if (e.value > 0) e.key,
    },
  );
}
