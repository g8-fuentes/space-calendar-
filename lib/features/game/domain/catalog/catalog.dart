import 'dart:math' as math;

import '../../../../core/text/text_utils.dart';

/// Converte HSL (h em graus, s e l de 0 a 1) para ARGB.
int hslToArgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  final (r, g, b) = switch (h) {
    < 60 => (c, x, 0.0),
    < 120 => (x, c, 0.0),
    < 180 => (0.0, c, x),
    < 240 => (0.0, x, c),
    < 300 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
  return 0xFF000000 | ch(r) << 16 | ch(g) << 8 | ch(b);
}

// ---------- Categorias ----------

class Category {
  const Category(this.key, this.name, this.color, this.rate);
  final String key;
  final String name;
  final int color;

  /// XP por hora de missão.
  final int rate;
}

const categories = <Category>[
  Category('cuidado', 'Vitalidade', 0xFFD27E99, 12),
  Category('estudo', 'Mente', 0xFF7FB4CA, 30),
  Category('trabalho', 'Foco', 0xFF7E9CD8, 15),
  Category('treino', 'Força', 0xFFC34043, 40),
  Category('arte', 'Criatividade', 0xFF957FB8, 35),
  Category('espirito', 'Espírito', 0xFFE6C384, 35),
  Category('lazer', 'Diversão', 0xFF98BB6C, 10),
];

Category categoryOf(String key) =>
    categories.firstWhere((c) => c.key == key, orElse: () => categories.first);

final _categoryRules = <(String, RegExp)>[
  ('treino', RegExp(r'academia|treino|gym|muscul|pilates|yoga|ioga|corrida|correr|run|futebol|futsal|futevolei|volei|basquete|natacao|nadar|bike|ciclismo|crossfit|luta|jiu|boxe|muay|danca|caminhada|alongamento|workout|esporte|tenis|beach')),
  ('estudo', RegExp(r'aula|estud|curso|leitura|ler |livro|duolingo|idioma|ingles|espanhol|frances|alemao|italiano|japones|english|spanish|study|class|lesson|reading|coddy|program|codigo|faculdade|escola|prova|revis|podcast')),
  ('trabalho', RegExp(r'trabalho|reuniao|work|meeting|call|expediente|escritorio|cliente|projeto|daily|standup|1:1|freela')),
  ('arte', RegExp(r'piano|violao|guitarra|musica|canto|bateria|foto|desenho|pintura|arte|escrita|escrever|music|draw|paint|teatro|croche|bordado')),
  ('espirito', RegExp(r'missa|igreja|culto|oracao|orar|meditac|meditar|terco|biblia|retiro|devocional|gratidao')),
  ('lazer', RegExp(r'jogo|game|filme|serie|lazer|passeio|festa|amigos|cinema|descanso|hobby')),
];

/// Adivinha a categoria pelo nome do evento.
String guessCategory(String title) {
  final n = '${norm(title)} ';
  for (final (k, rx) in _categoryRules) {
    if (rx.hasMatch(n)) return k;
  }
  return 'cuidado';
}

const dayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const dayAbbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

// ---------- Ranks, trajes e modos ----------

class Rank {
  const Rank(this.level, this.name, this.color);
  final int level;
  final String name;
  final int color;
}

const _baseRanks = [
  Rank(1, 'Cadete Mirim', 0xFF938AA9),
  Rank(4, 'Astronauta Júnior', 0xFF98BB6C),
  Rank(8, 'Piloto Espacial', 0xFF7FB4CA),
  Rank(13, 'Comandante de Missão', 0xFFE46876),
  Rank(19, 'Capitão Estelar', 0xFF957FB8),
  Rank(26, 'Almirante Galáctico', 0xFFE6C384),
];

const colorCycle = [
  0xFFE6C384, 0xFF7FB4CA, 0xFF957FB8, 0xFF98BB6C,
  0xFFE46876, 0xFFFFA066, 0xFFA3D4D5, 0xFFD27E99,
];

Rank rankAt(int i) {
  if (i < _baseRanks.length) return _baseRanks[i];
  final k = i - _baseRanks.length + 2;
  return Rank(26 + (i - _baseRanks.length + 1) * 8, 'Almirante Galáctico ${roman(k)}',
      colorCycle[k % colorCycle.length]);
}

int rankIndexFor(int lv) {
  if (lv < 26) {
    var i = 0;
    for (var j = 0; j < _baseRanks.length; j++) {
      if (lv >= _baseRanks[j].level) i = j;
    }
    return i;
  }
  return _baseRanks.length - 1 + (lv - 26) ~/ 8;
}

const _suits = [
  0xFFDCD7BA, 0xFF7E9CD8, 0xFF98BB6C, 0xFF957FB8,
  0xFFE6C384, 0xFFE46876, 0xFF7FB4CA, 0xFFFFA066,
];

int suitMkFor(int lv) => (lv - 1) ~/ 5 + 1;

int suitColor(int mk) =>
    mk <= _suits.length ? _suits[mk - 1] : hslToArgb(((mk * 47) % 360).toDouble(), 0.45, 0.68);

int suitAccent(int mk) => mk == 1 ? 0xFFFFA066 : (mk.isOdd ? 0xFFC34043 : 0xFF223249);

class SuitMode {
  const SuitMode(this.id, this.name, this.description, this.color, this.goldWeeks, this.level);
  final int id;
  final String name;
  final String description;
  final int color;
  final int goldWeeks;
  final int level;

  bool unlocked({required int gold, required int lv}) => id == 0 || gold >= goldWeeks || lv >= level;
}

const suitModes = [
  SuitMode(0, 'Traje padrão', 'Sempre disponível', 0xFF938AA9, 0, 0),
  SuitMode(1, 'Jetpack Turbo', '1 semana de ouro ou LV 10', 0xFFFFA066, 1, 10),
  SuitMode(2, 'Escudo de Plasma', '4 semanas de ouro ou LV 18', 0xFF7FB4CA, 4, 18),
  SuitMode(3, 'Modo Supernova', '10 semanas de ouro ou LV 28', 0xFFE6C384, 10, 28),
];

// ---------- Inimigos: um novo a cada nível, só visual ----------

const _foeKinds = [
  'Slime', 'Gárgula', 'Polvo', 'Verme', 'Espectro', 'Golem',
  'Morcego', 'Cristal', 'Medusa', 'Besouro', 'Ciclope', 'Cometa Vivo',
];
const _foeAdjectives = [
  'da Preguiça', 'do Sofá', 'da Soneca Eterna', 'do Scroll Infinito', 'da Desculpa', 'do Caos',
  'das Notificações', 'do Atraso', 'da Bagunça', 'do Tédio', 'da Distração', 'do Amanhã Eu Faço',
];
const _foePalettes = [
  [0xFF98BB6C, 0xFF76946A, 0xFFE46876],
  [0xFF957FB8, 0xFF54546D, 0xFFE6C384],
  [0xFFE46876, 0xFFC34043, 0xFFE6C384],
  [0xFF7FB4CA, 0xFF2D4F67, 0xFFFFA066],
  [0xFFFFA066, 0xFFC0A36E, 0xFF7FB4CA],
  [0xFFD27E99, 0xFF957FB8, 0xFF98BB6C],
  [0xFFA3D4D5, 0xFF6A9589, 0xFFC34043],
  [0xFFE6C384, 0xFFC0A36E, 0xFF957FB8],
];

class Enemy {
  const Enemy(this.level, this.name, this.grid, this.boss, this.color);
  final int level;
  final String name;

  /// Cores ARGB por pixel; 0 = transparente.
  final List<List<int>> grid;
  final bool boss;
  final int color;
  int get size => grid.length;
}

int _hashN(int n) {
  var h = (n * 2654435761) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 1274126177) & 0xFFFFFFFF;
  return h;
}

final _enemyCache = <int, Enemy>{};

/// Inimigo gerado a partir do nível: o mesmo nível sempre dá o mesmo bicho.
Enemy enemyFor(int lv) => _enemyCache.putIfAbsent(lv, () => _buildEnemy(lv));

Enemy _buildEnemy(int lv) {
  var r = _hashN(lv * 977 + 13);
  if (r == 0) r = 1;
  double rnd() {
    r ^= (r << 13) & 0xFFFFFFFF;
    r &= 0xFFFFFFFF;
    r ^= r >> 17;
    r ^= (r << 5) & 0xFFFFFFFF;
    r &= 0xFFFFFFFF;
    return r / 4294967296;
  }

  const ink = 0xFF16161D, white = 0xFFDCD7BA, gold = 0xFFE6C384;
  final boss = lv % 10 == 0;
  final n = boss ? 14 : 12, half = n ~/ 2;
  final pal = _foePalettes[(lv * 3 + (lv >> 3)) % _foePalettes.length];
  final g = List.generate(n, (_) => List.filled(n, 0));
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < half; x++) {
      final dx = (half - .5 - x) / half, dy = (y - n * .45) / (n * .55);
      final d = math.sqrt(dx * dx + dy * dy);
      final p = d < .55 ? .95 : d < .85 ? .55 : d < 1.05 ? .22 : 0.0;
      if (rnd() < p) {
        final c = rnd() < .22 ? pal[1] : pal[0];
        g[y][x] = c;
        g[y][n - 1 - x] = c;
      }
    }
  }
  final ey = (n * .38).floor(), ex = half - 3;
  for (final (x, y) in [(ex, ey), (n - 1 - ex - 1, ey)]) {
    g[y][x] = white;
    g[y][x + 1] = white;
    g[y + 1][x] = white;
    g[y + 1][x + 1] = ink;
  }
  if (rnd() < .5) {
    g[ey][half - 1] = pal[2];
    g[ey][half] = pal[2];
  }
  final my = (n * .66).floor();
  for (var x = half - 2; x < half + 2; x++) {
    g[my][x] = ink;
  }
  if (rnd() < .6) {
    g[my - 1][half - 2] = white;
    g[my - 1][half + 1] = white;
  }
  if (rnd() < .55 || boss) {
    g[0][half - 3] = pal[2];
    g[0][half + 2] = pal[2];
    g[1][half - 3] = pal[2];
    g[1][half + 2] = pal[2];
  }
  if (boss) {
    g[0][half - 1] = gold;
    g[0][half] = gold;
  }
  final out = [for (final row in g) List.of(row)];
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (g[y][x] != 0) continue;
      final near = (y > 0 && g[y - 1][x] != 0) ||
          (y < n - 1 && g[y + 1][x] != 0) ||
          (x > 0 && g[y][x - 1] != 0) ||
          (x < n - 1 && g[y][x + 1] != 0);
      if (near) out[y][x] = ink;
    }
  }
  final ki = (lv * 7) % _foeKinds.length;
  final ai = (lv * 5 + lv ~/ 12) % _foeAdjectives.length;
  final cycle = (lv - 1) ~/ 144;
  final name = '${boss ? 'Rei ' : ''}${_foeKinds[ki]} ${_foeAdjectives[ai]}${cycle > 0 ? ' ${roman(cycle + 1)}' : ''}';
  return Enemy(lv, name, out, boss, pal[0]);
}

// ---------- Loja ----------

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.slot = 'skin',
    this.suit,
    this.accent,
    this.color,
  });

  final String id;
  final String name;
  final int price;
  final String description;

  /// skin, look, pet, magic ou power.
  final String category;
  final String slot;
  final int? suit;
  final int? accent;
  final int? color;

  bool get isPower => category == 'power';

  /// Traje que muda de cor sem parar.
  bool get isAurora => id == 'sk_aur';
}

const shopSections = <(String, String)>[
  ('skin', 'Skins'),
  ('look', 'Aparências'),
  ('pet', 'Companheiros'),
  ('magic', 'Poderes mágicos'),
  ('power', 'Poderes'),
  ('ship', 'Nave'),
  ('real', 'Recompensas'),
];

const shopItems = <ShopItem>[
  ShopItem(id: 'sk_neb', name: 'Traje Nebulosa', price: 220, category: 'skin', suit: 0xFF957FB8, accent: 0xFFD27E99, description: 'Violeta com detalhes rosados.'),
  ShopItem(id: 'sk_sol', name: 'Traje Solar', price: 260, category: 'skin', suit: 0xFFE6C384, accent: 0xFFFFA066, description: 'Dourado como uma estrela anã.'),
  ShopItem(id: 'sk_gla', name: 'Traje Glacial', price: 260, category: 'skin', suit: 0xFFA3D4D5, accent: 0xFF7FB4CA, description: 'Feito para as luas geladas.'),
  ShopItem(id: 'sk_sha', name: 'Traje Sombra', price: 320, category: 'skin', suit: 0xFF54546D, accent: 0xFF957FB8, description: 'Discreto no vácuo escuro.'),
  ShopItem(id: 'sk_cor', name: 'Traje Coral', price: 320, category: 'skin', suit: 0xFFE46876, accent: 0xFFDCD7BA, description: 'Vermelho de exploração.'),
  ShopItem(id: 'sk_flo', name: 'Traje Floresta', price: 300, category: 'skin', suit: 0xFF76946A, accent: 0xFFE6C384, description: 'Lembrança da Terra.'),
  ShopItem(id: 'sk_aur', name: 'Traje Aurora', price: 900, category: 'skin', suit: 0, accent: 0xFFDCD7BA, description: 'Muda de cor sem parar.'),
  ShopItem(id: 'antenna', name: 'Antena no capacete', price: 60, category: 'look', slot: 'head', description: 'Recebe sinais da base.'),
  ShopItem(id: 'crown', name: 'Coroa estelar', price: 420, category: 'look', slot: 'head', description: 'Para quem já venceu muitos chefes.'),
  ShopItem(id: 'catears', name: 'Orelhas de gato', price: 180, category: 'look', slot: 'head', description: 'Capacete com orelhinhas.'),
  ShopItem(id: 'visor', name: 'Visor dourado', price: 160, category: 'look', slot: 'face', description: 'Protege do brilho do Sol.'),
  ShopItem(id: 'neon', name: 'Visor neon', price: 200, category: 'look', slot: 'face', description: 'Brilha em azul elétrico.'),
  ShopItem(id: 'stickers', name: 'Adesivos de foguete', price: 90, category: 'look', slot: 'body', description: 'Decoram o traje.'),
  ShopItem(id: 'scarf', name: 'Cachecol cósmico', price: 140, category: 'look', slot: 'body', description: 'Esvoaça mesmo sem vento.'),
  ShopItem(id: 'cape', name: 'Capa de comandante', price: 380, category: 'look', slot: 'back', description: 'Vermelha, comprida e dramática.'),
  ShopItem(id: 'flag', name: 'Bandeira da missão', price: 120, category: 'look', slot: 'hand', description: 'Para fincar em cada destino.'),
  ShopItem(id: 'saber', name: 'Sabre de plasma', price: 450, category: 'look', slot: 'hand', description: 'Só enfeite. Nada de lutar.'),
  ShopItem(id: 'robot', name: 'Robô ajudante', price: 300, category: 'pet', slot: 'pet', description: 'Um mini robô que flutua com você.'),
  ShopItem(id: 'cat', name: 'Gato espacial', price: 340, category: 'pet', slot: 'pet', description: 'Tem o próprio capacete-bolha.'),
  ShopItem(id: 'octo', name: 'Polvo alienígena', price: 380, category: 'pet', slot: 'pet', description: 'Amigável e curioso.'),
  ShopItem(id: 'dragon', name: 'Mini dragão estelar', price: 700, category: 'pet', slot: 'pet', description: 'Solta faíscas douradas.'),
  ShopItem(id: 'sat', name: 'Mini satélite', price: 350, category: 'pet', slot: 'orbit', description: 'Orbita ao seu redor.'),
  ShopItem(id: 'mg_arc', name: 'Aura arcana', price: 400, category: 'magic', slot: 'magic', color: 0xFF957FB8, description: 'Runas violetas giram ao seu redor.'),
  ShopItem(id: 'mg_star', name: 'Chuva de estrelas', price: 450, category: 'magic', slot: 'magic', color: 0xFFE6C384, description: 'Estrelas caem o tempo todo na cena.'),
  ShopItem(id: 'mg_fire', name: 'Fogo fantasma', price: 500, category: 'magic', slot: 'magic', color: 0xFF7FB4CA, description: 'Chamas azuis que não queimam.'),
  ShopItem(id: 'mg_portal', name: 'Portal dimensional', price: 650, category: 'magic', slot: 'magic', color: 0xFF6A9589, description: 'Um portal pulsa atrás de você.'),
  ShopItem(id: 'mg_halo', name: 'Halo dourado', price: 550, category: 'magic', slot: 'magic', color: 0xFFE6C384, description: 'Um anel de luz sobre o capacete.'),
  ShopItem(id: 'mg_comet', name: 'Rastro de cometa', price: 600, category: 'magic', slot: 'magic', color: 0xFFFFA066, description: 'Deixa um rastro de fogo no espaço.'),
  ShopItem(id: 'pw_boost', name: 'Impulso de XP', price: 90, category: 'power', color: 0xFF7FB4CA, description: '+50% de XP nas próximas 5 missões.'),
  ShopItem(id: 'pw_magnet', name: 'Ímã de moedas', price: 80, category: 'power', color: 0xFFE6C384, description: 'Dobra as moedas das próximas 5 missões.'),
  ShopItem(id: 'pw_shield', name: 'Escudo de plasma', price: 60, category: 'power', color: 0xFF98BB6C, description: 'Cancela a multa de um dia fraco.'),
  ShopItem(id: 'pw_hyper', name: 'Hiperpropulsão', price: 200, category: 'power', color: 0xFFE46876, description: '+150 XP na hora.'),
];

ShopItem? shopItem(String id) {
  for (final i in shopItems) {
    if (i.id == id) return i;
  }
  return null;
}

bool isCosmetic(String id) {
  final i = shopItem(id);
  return i != null && !i.isPower;
}

class Upgrade {
  const Upgrade(this.id, this.name, this.description, this.base, this.mult);
  final String id;
  final String name;
  final String description;
  final int base;
  final double mult;

  int cost(int level) => (base * math.pow(mult, level)).round();
}

const upgrades = [
  Upgrade('motor', 'Motor de dobra', '+5% moedas das missões por nível', 150, 1.6),
  Upgrade('antena', 'Antena de longo alcance', '+3% XP das missões por nível', 200, 1.7),
];

class ChestTier {
  const ChestTier(this.key, this.name, this.min, this.color, this.coins, this.xp, this.description);
  final String key;
  final String name;
  final double min;
  final int color;
  final int coins;
  final int xp;
  final String description;
}

const chestTiers = [
  ChestTier('bronze', 'Bronze', .6, 0xFFFFA066, 50, 20, '60% das missões'),
  ChestTier('prata', 'Prata', .8, 0xFFA3D4D5, 120, 60, '80% + item surpresa'),
  ChestTier('ouro', 'Ouro', 1, 0xFFE6C384, 250, 150, '100% + item + troféu'),
];

ChestTier tierByKey(String k) => chestTiers.firstWhere((t) => t.key == k, orElse: () => chestTiers.first);

ChestTier? tierFor(double ratio) {
  ChestTier? t;
  for (final x in chestTiers) {
    if (ratio >= x.min - 1e-9) t = x;
  }
  return t;
}

const weakDayPenalty = 15;
const lessonXp = 15;
const lessonCoins = 3;
const courseXp = 500;
const courseCoins = 200;
const courseLevelXp = 250;
const cefrLevels = [('A1', 0), ('A2', 500), ('B1', 1500), ('B2', 3000), ('C1', 5000), ('C2', 8000)];

const languageSuggestions = [
  'Inglês', 'Espanhol', 'Francês', 'Alemão', 'Italiano', 'Japonês',
  'Coreano', 'Mandarim', 'Russo', 'Árabe', 'Libras', 'Português',
];
