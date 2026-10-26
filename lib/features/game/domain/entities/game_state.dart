import 'dart:convert';

/// Uma missão semanal lida da agenda: repete nos [days] (0 = segunda ... 6 = domingo).
class Mission {
  Mission({
    required this.id,
    required this.title,
    required this.days,
    this.start = '',
    this.end = '',
    this.category = 'cuidado',
  });

  final String id;
  final String title;
  List<int> days;
  final String start;
  final String end;
  final String category;

  String get key => '${title.toLowerCase().trim()}|$start|$end';

  Map<String, Object?> toJson() => {'id': id, 't': title, 'days': days, 's': start, 'e': end, 'cat': category};

  factory Mission.fromJson(Map<String, Object?> j) => Mission(
        id: j['id']! as String,
        title: j['t']! as String,
        days: [for (final d in j['days']! as List) (d as num).toInt()],
        start: j['s'] as String? ?? '',
        end: j['e'] as String? ?? '',
        category: j['cat'] as String? ?? 'cuidado',
      );
}

/// Missão concluída num dia.
class DoneRecord {
  const DoneRecord({required this.day, required this.title, required this.at});

  final int day;
  final String title;
  final int at;

  Map<String, Object?> toJson() => {'d': day, 't': title, 'at': at};

  factory DoneRecord.fromJson(Map<String, Object?> j) => DoneRecord(
        day: (j['d'] as num?)?.toInt() ?? 0,
        title: j['t'] as String? ?? '',
        at: (j['at'] as num?)?.toInt() ?? 0,
      );
}

/// Uma semana: missões concluídas, por "idMissão@dia".
class WeekRecord {
  WeekRecord([Map<String, DoneRecord>? done]) : done = done ?? {};
  final Map<String, DoneRecord> done;

  Map<String, Object?> toJson() => {'done': {for (final e in done.entries) e.key: e.value.toJson()}};

  factory WeekRecord.fromJson(Map<String, Object?> j) => WeekRecord({
        for (final e in (j['done'] as Map? ?? {}).entries)
          e.key as String: DoneRecord.fromJson((e.value as Map).cast<String, Object?>()),
      });
}

/// Tudo o que é salvo. O lugar da exploração é sempre recalculado a
/// partir das missões concluídas (ver game_stats.dart).
class GameState {
  GameState({
    required this.startDate,
    this.name = '',
    this.onboarded = false,
    List<Mission>? missions,
    Map<String, WeekRecord>? weeks,
    this.sound = true,
    this.music = true,
    this.alerts = true,
    this.lastPlace = -1,
  })  : missions = missions ?? [],
        weeks = weeks ?? {};

  factory GameState.initial(String today) => GameState(startDate: today);

  String name;
  bool onboarded;
  List<Mission> missions;
  final Map<String, WeekRecord> weeks;
  bool sound;

  /// Música de fundo ligada.
  bool music;

  /// Notificação no celular quando uma missão começa.
  bool alerts;
  String startDate;

  /// Último lugar já anunciado (-1 = ainda não calculado).
  int lastPlace;

  WeekRecord week(String key) => weeks.putIfAbsent(key, WeekRecord.new);

  Map<String, Object?> toJson() => {
        'v': 3,
        'name': name,
        'onboarded': onboarded,
        'missions': [for (final m in missions) m.toJson()],
        'weeks': {for (final e in weeks.entries) e.key: e.value.toJson()},
        'sound': sound,
        'music': music,
        'alerts': alerts,
        'start': startDate,
        'lastPlace': lastPlace,
      };

  factory GameState.fromJson(Map<String, Object?> j, {required String today}) => GameState(
        startDate: j['start'] as String? ?? today,
        name: j['name'] as String? ?? '',
        onboarded: j['onboarded'] as bool? ?? false,
        missions: [
          for (final m in (j['missions'] as List? ?? const [])) Mission.fromJson((m as Map).cast<String, Object?>()),
        ],
        weeks: {
          for (final e in (j['weeks'] as Map? ?? {}).entries)
            e.key as String: WeekRecord.fromJson((e.value as Map).cast<String, Object?>()),
        },
        sound: j['sound'] as bool? ?? true,
        music: j['music'] as bool? ?? true,
        alerts: j['alerts'] as bool? ?? true,
        lastPlace: (j['lastPlace'] as num?)?.toInt() ?? -1,
      );

  /// Cópia profunda: as regras mexem na cópia e o controlador troca o estado.
  GameState copy() =>
      GameState.fromJson(jsonDecode(jsonEncode(toJson())) as Map<String, Object?>, today: startDate);
}
