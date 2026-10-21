import '../catalog/catalog.dart';

/// Itens do baú aberto em uma semana.
class ChestLoot {
  const ChestLoot({
    required this.tier,
    required this.coins,
    required this.xp,
    required this.bossDefeated,
    this.item,
  });

  final String tier;
  final int coins;
  final int xp;
  final bool bossDefeated;
  final String? item;

  Map<String, Object?> toJson() => {
        'tier': tier,
        'coins': coins,
        'xp': xp,
        'boss': bossDefeated,
        'item': item,
      };

  factory ChestLoot.fromJson(Map<String, Object?> j) => ChestLoot(
        tier: j['tier']! as String,
        coins: (j['coins']! as num).toInt(),
        xp: (j['xp'] as num? ?? 0).toInt(),
        bossDefeated: j['boss'] as bool? ?? false,
        item: j['item'] as String?,
      );
}

/// Progresso de uma semana: missões cumpridas (id -> horário) e baú.
class WeekRecord {
  const WeekRecord({this.done = const {}, this.chest});

  final Map<String, int> done;
  final ChestLoot? chest;

  WeekRecord copyWith({Map<String, int>? done, ChestLoot? chest}) =>
      WeekRecord(done: done ?? this.done, chest: chest ?? this.chest);

  Map<String, Object?> toJson() => {
        'done': done,
        'chest': chest?.toJson(),
      };

  factory WeekRecord.fromJson(Map<String, Object?> j) => WeekRecord(
        done: (j['done'] as Map<String, Object?>? ?? const {})
            .map((k, v) => MapEntry(k, (v! as num).toInt())),
        chest: j['chest'] == null
            ? null
            : ChestLoot.fromJson(j['chest']! as Map<String, Object?>),
      );
}

class Purchase {
  const Purchase(this.id, this.name, this.price, this.at);
  final String id;
  final String name;
  final int price;
  final int at;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'price': price, 'at': at};

  factory Purchase.fromJson(Map<String, Object?> j) => Purchase(
        j['id']! as String,
        j['name']! as String,
        (j['price']! as num).toInt(),
        (j['at']! as num).toInt(),
      );
}

class CourseProgress {
  const CourseProgress(this.done, this.total);
  final int done;
  final int total;

  bool get completed => total > 0 && done >= total;
  double get ratio => total <= 0 ? 0 : (done / total).clamp(0, 1).toDouble();

  Map<String, Object?> toJson() => {'done': done, 'total': total};

  factory CourseProgress.fromJson(Map<String, Object?> j) => CourseProgress(
        (j['done']! as num).toInt(),
        (j['total']! as num).toInt(),
      );
}

class LessonLog {
  const LessonLog(this.courseId, this.at, this.weekKey);
  final String courseId;
  final int at;
  final String weekKey;

  Map<String, Object?> toJson() => {'c': courseId, 'at': at, 'wk': weekKey};

  factory LessonLog.fromJson(Map<String, Object?> j) => LessonLog(
        j['c']! as String,
        (j['at']! as num).toInt(),
        j['wk']! as String,
      );
}

/// Estado completo e imutável do jogo. Tudo o que é derivado
/// (XP, moedas, nível, destino) é calculado em `GameStats`.
class GameState {
  const GameState({
    required this.weeks,
    required this.purchases,
    required this.owned,
    required this.equipped,
    required this.rewards,
    required this.courses,
    required this.lessons,
    required this.suitMode,
    required this.upgrades,
    required this.startDate,
    this.schemaVersion = currentSchema,
  });

  static const currentSchema = 1;

  final Map<String, WeekRecord> weeks;
  final List<Purchase> purchases;
  final Set<String> owned;
  final Map<String, String> equipped;
  final List<Reward> rewards;
  final Map<String, CourseProgress> courses;
  final List<LessonLog> lessons;
  final int suitMode;
  final Map<String, int> upgrades;

  /// Primeiro dia jogado (aaaa-mm-dd). Dias antes dele não contam
  /// como dias fracos.
  final String startDate;
  final int schemaVersion;

  factory GameState.initial(String startDate) => GameState(
        weeks: const {},
        purchases: const [],
        owned: const {},
        equipped: const {},
        rewards: defaultRewards,
        courses: {
          for (final c in courseCatalog) c.id: CourseProgress(0, c.defaultTotal),
        },
        lessons: const [],
        suitMode: 0,
        upgrades: const {'motor': 0, 'antena': 0},
        startDate: startDate,
      );

  WeekRecord week(String key) => weeks[key] ?? const WeekRecord();
  int upgradeLevel(String id) => upgrades[id] ?? 0;
  CourseProgress course(String id) =>
      courses[id] ?? const CourseProgress(0, 1);

  GameState copyWith({
    Map<String, WeekRecord>? weeks,
    List<Purchase>? purchases,
    Set<String>? owned,
    Map<String, String>? equipped,
    List<Reward>? rewards,
    Map<String, CourseProgress>? courses,
    List<LessonLog>? lessons,
    int? suitMode,
    Map<String, int>? upgrades,
    String? startDate,
  }) =>
      GameState(
        weeks: weeks ?? this.weeks,
        purchases: purchases ?? this.purchases,
        owned: owned ?? this.owned,
        equipped: equipped ?? this.equipped,
        rewards: rewards ?? this.rewards,
        courses: courses ?? this.courses,
        lessons: lessons ?? this.lessons,
        suitMode: suitMode ?? this.suitMode,
        upgrades: upgrades ?? this.upgrades,
        startDate: startDate ?? this.startDate,
      );

  Map<String, Object?> toJson() => {
        'schema': schemaVersion,
        'weeks': weeks.map((k, v) => MapEntry(k, v.toJson())),
        'purchases': purchases.map((p) => p.toJson()).toList(),
        'owned': owned.toList(),
        'equipped': equipped,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'courses': courses.map((k, v) => MapEntry(k, v.toJson())),
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'suitMode': suitMode,
        'upgrades': upgrades,
        'startDate': startDate,
      };

  factory GameState.fromJson(Map<String, Object?> j, {required String today}) {
    final base = GameState.initial(j['startDate'] as String? ?? today);
    List<Map<String, Object?>> list(String key) =>
        (j[key] as List<Object?>? ?? const [])
            .map((e) => e! as Map<String, Object?>)
            .toList();
    Map<String, Object?> map(String key) =>
        j[key] as Map<String, Object?>? ?? const {};

    final loadedCourses = map('courses').map((k, v) =>
        MapEntry(k, CourseProgress.fromJson(v! as Map<String, Object?>)));
    final rewardsJson = list('rewards');

    return base.copyWith(
      weeks: map('weeks').map(
          (k, v) => MapEntry(k, WeekRecord.fromJson(v! as Map<String, Object?>))),
      purchases: list('purchases').map(Purchase.fromJson).toList(),
      owned: (j['owned'] as List<Object?>? ?? const [])
          .whereType<String>()
          .where((id) => cosmeticById(id) != null)
          .toSet(),
      equipped: map('equipped')
          .map((k, v) => MapEntry(k, v as String? ?? ''))
        ..removeWhere((k, v) => cosmeticById(v) == null),
      rewards: rewardsJson.isEmpty
          ? defaultRewards
          : rewardsJson.map(Reward.fromJson).toList(),
      courses: {...base.courses, ...loadedCourses},
      lessons: list('lessons').map(LessonLog.fromJson).toList(),
      suitMode: (j['suitMode'] as num? ?? 0).toInt(),
      upgrades: {
        ...base.upgrades,
        ...map('upgrades').map((k, v) => MapEntry(k, (v! as num).toInt())),
      },
    );
  }
}
