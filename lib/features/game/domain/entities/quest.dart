import 'dart:math' as math;

/// Tipo de missão. Cada tipo alimenta um atributo e vale um XP por hora.
enum QuestCategory {
  cuidado('Vitalidade', 12),
  estudo('Mente', 30),
  trabalho('Foco', 15),
  treino('Força', 40),
  arte('Arte', 35),
  fe('Fé', 40);

  const QuestCategory(this.attribute, this.xpPerHour);

  final String attribute;
  final int xpPerHour;
}

/// Subquests que uma missão pode abrir.
enum SubquestKind { courses, selfHosted }

/// Uma missão da agenda semanal (um evento da agenda Rotina).
class Quest {
  const Quest({
    required this.id,
    required this.dayIndex,
    required this.start,
    required this.end,
    required this.title,
    required this.category,
    this.tag,
    this.subquests,
  });

  final String id;
  final int dayIndex;
  final String start;
  final String end;
  final String title;
  final QuestCategory category;

  /// Marcador usado por conquistas e trilhas (ex.: "es", "en", "piano").
  final String? tag;
  final SubquestKind? subquests;

  int get startMinutes => _toMinutes(start);
  int get endMinutes => _toMinutes(end);

  int get xp {
    if (tag == 'sono') return 25;
    if (tag == 'banho5') return 20;
    var hours = (endMinutes - startMinutes) / 60;
    // Os dois idiomas dividem o mesmo horário.
    if (tag == 'es' || tag == 'en') hours /= 2;
    final clamped = math.min(4.0, math.max(0.5, hours));
    return (category.xpPerHour * clamped).round();
  }

  int get coins => math.max(1, (xp / 5).round());

  bool isLiveAt(int minuteOfDay) =>
      minuteOfDay >= startMinutes && minuteOfDay < endMinutes;

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class DaySchedule {
  const DaySchedule(this.name, this.short, this.quests);

  final String name;
  final String short;
  final List<Quest> quests;
}
