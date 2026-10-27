import 'catalog.dart' show hslToArgb;

/// Penteado do personagem.
enum Hair { normal, spiky, long }

/// Roupa da pessoa (na Terra). No espaço ele usa o traje de astronauta,
/// tingido pela transformação.
enum Outfit { casual, training, gi, giCape, divine }

/// Uma transformação: só visual, liberada pelo poder total (soma dos
/// pontos dos atributos).
class Transformation {
  const Transformation({
    required this.index,
    required this.name,
    required this.power,
    required this.description,
    this.aura = 0,
    this.auraColor = 0xFFFFFFFF,
    this.hair = Hair.normal,
    this.hairColor = 0xFF2E1D14,
    this.outfit = Outfit.casual,
    this.eyes = 0xFF16161D,
    this.lightning = false,
    this.cosmic = false,
  });

  final int index;
  final String name;

  /// Poder total para liberar.
  final int power;
  final String description;

  /// Força da aura: 0 = nenhuma, 1 = brilho, 2 = chamas, 3 = chamas fortes.
  final int aura;
  final int auraColor;
  final Hair hair;
  final int hairColor;
  final Outfit outfit;
  final int eyes;

  /// Raios em volta do corpo.
  final bool lightning;

  /// Cores mudando sem parar.
  final bool cosmic;
}

const _gold = 0xFFFFD84A, _teal = 0xFF2FB5A3;

const _forms = <Transformation>[
  Transformation(index: 0, name: 'Pessoa comum', power: 0, description: 'Camiseta, jeans e uma agenda cheia.'),
  Transformation(
      index: 1,
      name: 'Focado',
      power: 40,
      outfit: Outfit.training,
      description: 'Roupa de treino nova: a rotina começou de verdade.'),
  Transformation(
      index: 2,
      name: 'Despertar',
      power: 120,
      aura: 1,
      outfit: Outfit.training,
      description: 'Uma aura branca aparece em volta do corpo.'),
  Transformation(
      index: 3,
      name: 'Guerreiro',
      power: 250,
      aura: 1,
      auraColor: 0xFFA3D4D5,
      outfit: Outfit.gi,
      description: 'Uniforme de luta laranja e aura azul-clara.'),
  Transformation(
      index: 4,
      name: 'Super Guerreiro',
      power: 450,
      aura: 2,
      auraColor: _gold,
      hair: Hair.spiky,
      hairColor: _gold,
      outfit: Outfit.gi,
      eyes: _teal,
      description: 'Cabelo dourado espetado, olhos verdes e aura de fogo dourada.'),
  Transformation(
      index: 5,
      name: 'Super Guerreiro 2',
      power: 700,
      aura: 2,
      auraColor: _gold,
      hair: Hair.spiky,
      hairColor: _gold,
      outfit: Outfit.gi,
      eyes: _teal,
      lightning: true,
      description: 'Raios elétricos estalam dentro da aura.'),
  Transformation(
      index: 6,
      name: 'Super Guerreiro 3',
      power: 1000,
      aura: 3,
      auraColor: _gold,
      hair: Hair.long,
      hairColor: _gold,
      outfit: Outfit.giCape,
      eyes: _teal,
      lightning: true,
      description: 'Cabelo dourado até a cintura e uma capa vermelha.'),
  Transformation(
      index: 7,
      name: 'Guerreiro Divino',
      power: 1400,
      aura: 3,
      auraColor: 0xFFFF5D62,
      hair: Hair.spiky,
      hairColor: 0xFFE8506A,
      outfit: Outfit.giCape,
      eyes: 0xFFC34043,
      description: 'Cabelo e aura vermelhos: o poder de um deus.'),
  Transformation(
      index: 8,
      name: 'Supremo Azul',
      power: 1900,
      aura: 3,
      auraColor: 0xFF7FB4CA,
      hair: Hair.spiky,
      hairColor: 0xFF5FB7E8,
      outfit: Outfit.giCape,
      eyes: 0xFF7E9CD8,
      lightning: true,
      description: 'Cabelo azul e aura azul com raios.'),
  Transformation(
      index: 9,
      name: 'Instinto Prateado',
      power: 2500,
      aura: 3,
      auraColor: 0xFFDCD7BA,
      hair: Hair.spiky,
      hairColor: 0xFFE4E6EE,
      outfit: Outfit.divine,
      eyes: 0xFFA3D4D5,
      description: 'Cabelo prateado, roupa sagrada e calma total.'),
  Transformation(
      index: 10,
      name: 'Ultra Cósmico',
      power: 3200,
      aura: 3,
      hair: Hair.long,
      outfit: Outfit.divine,
      lightning: true,
      cosmic: true,
      description: 'Aura e cabelo mudam de cor como uma galáxia.'),
];

final _cache = <int, Transformation>{};

/// Transformação [i]. Depois da Ultra Cósmica, um novo nível a cada 1.000 pontos.
Transformation transformationAt(int i) {
  if (i < _forms.length) return _forms[i];
  return _cache.putIfAbsent(i, () {
    final n = i - _forms.length + 2;
    final hue = (i * 47 % 360).toDouble();
    return Transformation(
      index: i,
      name: 'Ultra Cósmico $n',
      power: _forms.last.power + (n - 1) * 1000,
      aura: 3,
      auraColor: hslToArgb(hue, .7, .65),
      hair: Hair.long,
      hairColor: hslToArgb(hue, .7, .7),
      outfit: Outfit.divine,
      lightning: true,
      cosmic: true,
      description: 'Mais um nível de poder cósmico.',
    );
  });
}

int transformationIndexFor(int power) {
  var i = 0;
  while (transformationAt(i + 1).power <= power) {
    i++;
  }
  return i;
}

int get namedTransformations => _forms.length;
