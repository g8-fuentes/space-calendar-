import 'dart:convert';

/// Uma missão semanal: repete nos [days] (0 = segunda ... 6 = domingo).
class Mission {
  Mission({
    required this.id,
    required this.title,
    required this.days,
    this.start = '',
    this.end = '',
    this.category = 'cuidado',
    this.link,
    this.synced = false,
  });

  final String id;
  String title;
  List<int> days;
  String start;
  String end;
  String category;

  /// Curso ou idioma que recebe o XP desta missão.
  String? link;

  /// Veio da sincronização com o Google Agenda.
  bool synced;

  String get key => '${title.toLowerCase().trim()}|$start|$end';

  Map<String, Object?> toJson() => {
        'id': id,
        't': title,
        'days': days,
        's': start,
        'e': end,
        'cat': category,
        'link': link,
        if (synced) 'g': true,
      };

  factory Mission.fromJson(Map<String, Object?> j) => Mission(
        id: j['id']! as String,
        title: j['t']! as String,
        days: [for (final d in j['days']! as List) (d as num).toInt()],
        start: j['s'] as String? ?? '',
        end: j['e'] as String? ?? '',
        category: j['cat'] as String? ?? 'cuidado',
        link: j['link'] as String?,
        synced: j['g'] as bool? ?? false,
      );
}

/// Curso livre (kind 'course') ou idioma (kind 'lang').
class Course {
  Course({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    this.total,
    this.lessons = 0,
    this.finished = false,
  });

  final String id;
  String name;
  final String kind;
  final int color;
  int? total;
  int lessons;
  bool finished;

  bool get isLanguage => kind == 'lang';

  Map<String, Object?> toJson() => {
        'id': id,
        'n': name,
        'kind': kind,
        'color': color,
        'total': total,
        'lessons': lessons,
        'finished': finished,
      };

  factory Course.fromJson(Map<String, Object?> j) => Course(
        id: j['id']! as String,
        name: j['n']! as String,
        kind: j['kind'] as String? ?? 'course',
        color: (j['color'] as num?)?.toInt() ?? 0xFF7FB4CA,
        total: (j['total'] as num?)?.toInt(),
        lessons: (j['lessons'] as num?)?.toInt() ?? 0,
        finished: j['finished'] as bool? ?? false,
      );
}

/// Registro de uma missão concluída num dia da semana. Guarda o XP e
/// as moedas do momento, então editar a missão depois não muda o passado.
class DoneRecord {
  const DoneRecord({
    required this.xp,
    required this.coins,
    required this.day,
    required this.category,
    required this.title,
    required this.at,
    this.courseId,
    this.boost = false,
    this.magnet = false,
  });

  final int xp;
  final int coins;
  final int day;
  final String category;
  final String title;
  final int at;
  final String? courseId;
  final bool boost;
  final bool magnet;

  Map<String, Object?> toJson() => {
        'xp': xp,
        'coins': coins,
        'd': day,
        'cat': category,
        't': title,
        'at': at,
        'c': courseId,
        'boost': boost,
        'magnet': magnet,
      };

  factory DoneRecord.fromJson(Map<String, Object?> j) => DoneRecord(
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        day: (j['d'] as num?)?.toInt() ?? 0,
        category: j['cat'] as String? ?? 'cuidado',
        title: j['t'] as String? ?? '',
        at: (j['at'] as num?)?.toInt() ?? 0,
        courseId: j['c'] as String?,
        boost: j['boost'] as bool? ?? false,
        magnet: j['magnet'] as bool? ?? false,
      );
}

class Chest {
  const Chest({required this.tier, required this.coins, required this.xp, this.item});
  final String tier;
  final int coins;
  final int xp;
  final String? item;

  Map<String, Object?> toJson() => {'tier': tier, 'coins': coins, 'xp': xp, 'item': item};

  factory Chest.fromJson(Map<String, Object?> j) => Chest(
        tier: j['tier'] as String? ?? 'bronze',
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        item: j['item'] as String?,
      );
}

class WeekRecord {
  WeekRecord({Map<String, DoneRecord>? done, this.chest}) : done = done ?? {};
  final Map<String, DoneRecord> done;
  Chest? chest;

  Map<String, Object?> toJson() => {
        'done': {for (final e in done.entries) e.key: e.value.toJson()},
        'chest': chest?.toJson(),
      };

  factory WeekRecord.fromJson(Map<String, Object?> j) => WeekRecord(
        done: {
          for (final e in (j['done'] as Map? ?? {}).entries)
            e.key as String: DoneRecord.fromJson((e.value as Map).cast<String, Object?>()),
        },
        chest: j['chest'] == null ? null : Chest.fromJson((j['chest']! as Map).cast<String, Object?>()),
      );
}

class Purchase {
  const Purchase({required this.id, required this.name, required this.price, required this.at});
  final String id;
  final String name;
  final int price;
  final int at;

  Map<String, Object?> toJson() => {'id': id, 'n': name, 'p': price, 'at': at};

  factory Purchase.fromJson(Map<String, Object?> j) => Purchase(
        id: j['id'] as String? ?? '',
        name: j['n'] as String? ?? '',
        price: (j['p'] as num?)?.toInt() ?? 0,
        at: (j['at'] as num?)?.toInt() ?? 0,
      );
}

class Reward {
  const Reward({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final int price;

  Map<String, Object?> toJson() => {'id': id, 'n': name, 'p': price};

  factory Reward.fromJson(Map<String, Object?> j) => Reward(
        id: j['id'] as String? ?? '',
        name: j['n'] as String? ?? '',
        price: (j['p'] as num?)?.toInt() ?? 0,
      );
}

/// Tudo o que é salvo. XP, moedas, nível e destino são sempre
/// recalculados a partir daqui (ver game_stats.dart).
class GameState {
  GameState({
    required this.startDate,
    this.name = '',
    this.onboarded = false,
    List<Mission>? missions,
    List<Course>? courses,
    Map<String, WeekRecord>? weeks,
    List<Purchase>? purchases,
    List<String>? owned,
    Map<String, String>? equipped,
    this.boostCharges = 0,
    this.magnetCharges = 0,
    this.shields = 0,
    this.bonusXp = 0,
    List<Reward>? rewards,
    this.suitMode = 0,
    this.lastLevel = 1,
    this.lastRank = 0,
    this.lastDestination = 0,
    this.lastModeSeen = 0,
    Map<String, int>? upgrades,
    this.sound = true,
    this.calendarUrl,
    this.lastSync,
    this.music = true,
    this.alerts = true,
  })  : missions = missions ?? [],
        courses = courses ?? [],
        weeks = weeks ?? {},
        purchases = purchases ?? [],
        owned = owned ?? [],
        equipped = equipped ?? {},
        rewards = rewards ?? _defaultRewards(),
        upgrades = upgrades ?? {'motor': 0, 'antena': 0};

  factory GameState.initial(String today) => GameState(startDate: today);

  String name;
  bool onboarded;
  List<Mission> missions;
  List<Course> courses;
  final Map<String, WeekRecord> weeks;
  final List<Purchase> purchases;
  final List<String> owned;
  final Map<String, String> equipped;
  int boostCharges;
  int magnetCharges;
  int shields;
  int bonusXp;
  List<Reward> rewards;
  int suitMode;
  int lastLevel;
  int lastRank;
  int lastDestination;
  int lastModeSeen;
  final Map<String, int> upgrades;
  bool sound;
  String startDate;

  /// Endereço secreto iCal do Google Agenda, quando conectado.
  String? calendarUrl;

  /// Última sincronização (ms desde epoch).
  int? lastSync;

  /// Música de fundo ligada.
  bool music;

  /// Notificação no celular quando uma missão começa.
  bool alerts;

  static List<Reward> _defaultRewards() => const [
        Reward(id: 'r1', name: 'Noite de filme sem culpa', price: 100),
        Reward(id: 'r2', name: 'Sobremesa favorita', price: 150),
        Reward(id: 'r3', name: 'Comprar um jogo novo', price: 600),
      ];

  WeekRecord week(String key) => weeks.putIfAbsent(key, WeekRecord.new);
  int upgradeLevel(String id) => upgrades[id] ?? 0;
  Course? course(String? id) {
    if (id == null) return null;
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  Mission? mission(String id) {
    for (final m in missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'v': 2,
        'name': name,
        'onboarded': onboarded,
        'missions': [for (final m in missions) m.toJson()],
        'courses': [for (final c in courses) c.toJson()],
        'weeks': {for (final e in weeks.entries) e.key: e.value.toJson()},
        'spent': [for (final p in purchases) p.toJson()],
        'owned': owned,
        'equip': equipped,
        'boost': boostCharges,
        'magnet': magnetCharges,
        'shields': shields,
        'bonusXp': bonusXp,
        'rewards': [for (final r in rewards) r.toJson()],
        'form': suitMode,
        'lastLevel': lastLevel,
        'lastRank': lastRank,
        'lastDest': lastDestination,
        'lastFormSeen': lastModeSeen,
        'up': upgrades,
        'sound': sound,
        'start': startDate,
        'gcal': calendarUrl,
        'gsync': lastSync,
        'music': music,
        'alerts': alerts,
      };

  factory GameState.fromJson(Map<String, Object?> j, {required String today}) {
    List<Map<String, Object?>> list(String k) =>
        [for (final e in (j[k] as List? ?? const [])) (e as Map).cast<String, Object?>()];
    return GameState(
      startDate: j['start'] as String? ?? today,
      name: j['name'] as String? ?? '',
      onboarded: j['onboarded'] as bool? ?? false,
      missions: [for (final m in list('missions')) Mission.fromJson(m)],
      courses: [for (final c in list('courses')) Course.fromJson(c)],
      weeks: {
        for (final e in (j['weeks'] as Map? ?? {}).entries)
          e.key as String: WeekRecord.fromJson((e.value as Map).cast<String, Object?>()),
      },
      purchases: [for (final p in list('spent')) Purchase.fromJson(p)],
      owned: [for (final o in (j['owned'] as List? ?? const [])) o as String],
      equipped: (j['equip'] as Map? ?? {}).cast<String, String>(),
      boostCharges: (j['boost'] as num?)?.toInt() ?? 0,
      magnetCharges: (j['magnet'] as num?)?.toInt() ?? 0,
      shields: (j['shields'] as num?)?.toInt() ?? 0,
      bonusXp: (j['bonusXp'] as num?)?.toInt() ?? 0,
      rewards: j['rewards'] == null ? null : [for (final r in list('rewards')) Reward.fromJson(r)],
      suitMode: (j['form'] as num?)?.toInt() ?? 0,
      lastLevel: (j['lastLevel'] as num?)?.toInt() ?? 1,
      lastRank: (j['lastRank'] as num?)?.toInt() ?? 0,
      lastDestination: (j['lastDest'] as num?)?.toInt() ?? 0,
      lastModeSeen: (j['lastFormSeen'] as num?)?.toInt() ?? 0,
      upgrades: {
        'motor': 0,
        'antena': 0,
        ...(j['up'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      },
      sound: j['sound'] as bool? ?? true,
      calendarUrl: j['gcal'] as String?,
      lastSync: (j['gsync'] as num?)?.toInt(),
      music: j['music'] as bool? ?? true,
      alerts: j['alerts'] as bool? ?? true,
    );
  }

  /// Cópia profunda: as regras mexem na cópia e o controlador troca o estado.
  GameState copy() => GameState.fromJson(
      jsonDecode(jsonEncode(toJson())) as Map<String, Object?>,
      today: startDate);
}
