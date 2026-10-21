import 'dart:math' as math;

/// Dados fixos do jogo. Cores são ARGB (int) para manter o domínio
/// independente do Flutter.

// ---------------- Cursos ----------------
class Course {
  const Course(this.id, this.name, this.defaultTotal, this.color);
  final String id;
  final String name;
  final int defaultTotal;
  final int color;
}

const courseCatalog = <Course>[
  Course('rocket', 'Rocketseat', 60, 0xFF957FB8),
  Course('origamid', 'Origamid', 80, 0xFFE6C384),
  Course('reactadv', 'React Avançado', 40, 0xFF7FB4CA),
  Course('deschamps', 'Curso Filipe Deschamps', 30, 0xFF98BB6C),
  Course('self', 'Self-hosted', 25, 0xFFC34043),
];

const lessonXp = 15;
const lessonCoins = 3;
const courseXp = 500;
const courseCoins = 200;

// ---------------- Ranks (infinitos) ----------------
class Rank {
  const Rank(this.level, this.name, this.color);
  final int level;
  final String name;
  final int color;
}

const _baseRanks = <Rank>[
  Rank(1, 'Cadete Mirim', 0xFF938AA9),
  Rank(4, 'Astronauta Júnior', 0xFF98BB6C),
  Rank(8, 'Piloto Espacial', 0xFF7FB4CA),
  Rank(13, 'Comandante de Missão', 0xFFE46876),
  Rank(19, 'Capitão Estelar', 0xFF957FB8),
  Rank(26, 'Almirante Galáctico', 0xFFE6C384),
];

const _cycle = <int>[
  0xFFE6C384, 0xFF7FB4CA, 0xFF957FB8, 0xFF98BB6C,
  0xFFE46876, 0xFFFFA066, 0xFFA3D4D5, 0xFFD27E99,
];

/// A cada 8 níveis depois do 26 surge um novo "Almirante Galáctico N".
const rankStepAfterBase = 8;

Rank rankAt(int index) {
  if (index < _baseRanks.length) return _baseRanks[index];
  final k = index - _baseRanks.length + 2;
  return Rank(
    26 + (index - _baseRanks.length + 1) * rankStepAfterBase,
    'Almirante Galáctico ${roman(k)}',
    _cycle[k % _cycle.length],
  );
}

int rankIndexFor(int level) {
  if (level < 26) {
    var i = 0;
    for (var j = 0; j < _baseRanks.length; j++) {
      if (level >= _baseRanks[j].level) i = j;
    }
    return i;
  }
  return _baseRanks.length - 1 + (level - 26) ~/ rankStepAfterBase;
}

String roman(int n) {
  const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const symbols = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
  final b = StringBuffer();
  var rest = n;
  for (var i = 0; i < values.length; i++) {
    while (rest >= values[i]) {
      b.write(symbols[i]);
      rest -= values[i];
    }
  }
  return b.toString();
}

// ---------------- Traje Mk (infinito) ----------------
const suitLevelsPerMk = 5;
int suitMkFor(int level) => (level - 1) ~/ suitLevelsPerMk + 1;
int suitMkStartLevel(int mk) => (mk - 1) * suitLevelsPerMk + 1;

const _suitColors = <int>[
  0xFFDCD7BA, 0xFF7E9CD8, 0xFF98BB6C, 0xFF957FB8,
  0xFFE6C384, 0xFFE46876, 0xFF7FB4CA, 0xFFFFA066,
];

int suitColor(int mk) {
  if (mk <= _suitColors.length) return _suitColors[mk - 1];
  return hslToArgb((mk * 47) % 360 + 0.0, 0.45, 0.68);
}

int suitAccent(int mk) =>
    mk == 1 ? 0xFFFFA066 : (mk.isOdd ? 0xFFC34043 : 0xFF223249);

// ---------------- Modos do traje ----------------
class SuitMode {
  const SuitMode(this.id, this.name, this.requirement, this.color,
      this.goldWeeks, this.level);
  final int id;
  final String name;
  final String requirement;
  final int color;
  final int goldWeeks;
  final int level;

  bool unlocked({required int gold, required int lv}) =>
      id == 0 || gold >= goldWeeks || lv >= level;
}

const suitModes = <SuitMode>[
  SuitMode(0, 'Traje padrão', 'Sempre disponível', 0xFF938AA9, 0, 1),
  SuitMode(1, 'Jetpack Turbo', '1 semana de ouro ou LV 10', 0xFFFFA066, 1, 10),
  SuitMode(2, 'Escudo de Plasma', '4 semanas de ouro ou LV 18', 0xFF7FB4CA, 4, 18),
  SuitMode(3, 'Modo Supernova', '10 semanas de ouro ou LV 28', 0xFFE6C384, 10, 28),
];

// ---------------- Chefes semanais ----------------
class Boss {
  const Boss(this.name, this.color, this.hp);
  final String name;
  final int color;
  final int hp;
}

const _bosses = <(String, int)>[
  ('Chuva de Meteoros', 0xFFFFA066),
  ('Tempestade Solar', 0xFFE6C384),
  ('Buraco Negro da Preguiça', 0xFF957FB8),
  ('Alien da Procrastinação', 0xFF98BB6C),
  ('Lixo Espacial do Celular', 0xFF7FB4CA),
  ('Asteroide do Sofá', 0xFF938AA9),
];

int stringHash(String s) {
  var h = 0;
  for (final unit in s.codeUnits) {
    h = (h * 31 + unit) & 0xFFFFFFFF;
  }
  return h;
}

Boss bossForWeek(String weekKey, int weekMaxXp) {
  final b = _bosses[stringHash(weekKey) % _bosses.length];
  return Boss(b.$1, b.$2, (weekMaxXp * 0.7).round());
}

const bossBonusCoins = 100;
const bossBonusXp = 80;

// ---------------- Baú semanal ----------------
class ChestTier {
  const ChestTier(this.key, this.name, this.minRatio, this.color, this.coins,
      this.xp, this.description);
  final String key;
  final String name;
  final double minRatio;
  final int color;
  final int coins;
  final int xp;
  final String description;
}

const chestTiers = <ChestTier>[
  ChestTier('bronze', 'Bronze', 0.6, 0xFFFFA066, 50, 20, '60% das missões'),
  ChestTier('prata', 'Prata', 0.8, 0xFFA3D4D5, 120, 60, '80% + item surpresa'),
  ChestTier('ouro', 'Ouro', 1.0, 0xFFE6C384, 250, 150, '100% + item + troféu'),
];

ChestTier? tierFor(double ratio) {
  ChestTier? found;
  for (final t in chestTiers) {
    if (ratio >= t.minRatio - 1e-9) found = t;
  }
  return found;
}

ChestTier tierByKey(String key) => chestTiers.firstWhere((t) => t.key == key);

/// Moedas perdidas por dia passado com menos de 50% das missões.
const weakDayPenalty = 15;

// ---------------- Loja ----------------
enum CosmeticSlot { head, body, face, hand, pet, satellite }

class Cosmetic {
  const Cosmetic(this.id, this.name, this.price, this.slot, this.description);
  final String id;
  final String name;
  final int price;
  final CosmeticSlot slot;
  final String description;
}

const cosmeticCatalog = <Cosmetic>[
  Cosmetic('antenna', 'Antena no capacete', 60, CosmeticSlot.head, 'Recebe sinais da base.'),
  Cosmetic('stickers', 'Adesivos de foguete', 90, CosmeticSlot.body, 'Decoram o traje.'),
  Cosmetic('visor', 'Visor dourado', 160, CosmeticSlot.face, 'Protege do brilho do Sol.'),
  Cosmetic('flag', 'Bandeira da missão', 120, CosmeticSlot.hand, 'Para fincar em cada destino.'),
  Cosmetic('robot', 'Robô ajudante', 300, CosmeticSlot.pet, 'Um mini robô que flutua com você.'),
  Cosmetic('sat', 'Mini satélite', 350, CosmeticSlot.satellite, 'Orbita ao seu redor.'),
];

Cosmetic? cosmeticById(String id) {
  for (final c in cosmeticCatalog) {
    if (c.id == id) return c;
  }
  return null;
}

class Upgrade {
  const Upgrade(this.id, this.name, this.description, this.base, this.multiplier,
      this.percentPerLevel);
  final String id;
  final String name;
  final String description;
  final int base;
  final double multiplier;
  final int percentPerLevel;

  int costFor(int level) => (base * math.pow(multiplier, level)).round();
}

const upgradeCatalog = <Upgrade>[
  Upgrade('motor', 'Motor de dobra', '+5% moedas das missões por nível', 150, 1.6, 5),
  Upgrade('antena', 'Antena de longo alcance', '+3% XP das missões por nível', 200, 1.7, 3),
];

class Reward {
  const Reward(this.id, this.name, this.price);
  final String id;
  final String name;
  final int price;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'price': price};
  factory Reward.fromJson(Map<String, Object?> j) =>
      Reward(j['id']! as String, j['name']! as String, (j['price']! as num).toInt());
}

const defaultRewards = <Reward>[
  Reward('r1', 'Noite de filme sem culpa', 100),
  Reward('r2', 'Hambúrguer no fim de semana', 150),
  Reward('r3', 'Dormir até mais tarde no sábado', 120),
  Reward('r4', 'Comprar um jogo novo', 600),
];

// ---------------- Cores ----------------
int hslToArgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = (h % 360) / 60;
  final x = c * (1 - ((hp % 2) - 1).abs());
  double r = 0, g = 0, b = 0;
  if (hp < 1) {
    r = c;
    g = x;
  } else if (hp < 2) {
    r = x;
    g = c;
  } else if (hp < 3) {
    g = c;
    b = x;
  } else if (hp < 4) {
    g = x;
    b = c;
  } else if (hp < 5) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  final m = l - c / 2;
  int to(double v) => math.max(0, math.min(255, ((v + m) * 255).round()));
  return 0xFF000000 | (to(r) << 16) | (to(g) << 8) | to(b);
}
