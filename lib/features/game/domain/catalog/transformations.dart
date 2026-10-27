import 'catalog.dart' show hslToArgb;

/// Penteado do personagem.
enum Hair { normal, spiky, wild, long, flame }

/// Roupa do dev lutador.
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

  /// Força da aura: 0 = nenhuma, 1 = brilho, 2 = chamas, 3 = chamas fortes,
  /// 4 = com anel de faíscas, 5 = chama dupla gigante.
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

Transformation _f(int i, String name, int power, String description,
        {int aura = 0,
        int auraColor = 0xFFFFFFFF,
        Hair hair = Hair.normal,
        int hairColor = 0xFF2E1D14,
        Outfit outfit = Outfit.casual,
        int eyes = 0xFF16161D,
        bool lightning = false,
        bool cosmic = false}) =>
    Transformation(
      index: i,
      name: name,
      power: power,
      description: description,
      aura: aura,
      auraColor: auraColor,
      hair: hair,
      hairColor: hairColor,
      outfit: outfit,
      eyes: eyes,
      lightning: lightning,
      cosmic: cosmic,
    );

final _forms = <Transformation>[
  _f(0, 'Dev iniciante', 0, 'Camiseta com </>, jeans e uma agenda cheia.'),
  _f(1, 'Dev focado', 40, 'Moletom de treino: entre um commit e outro, ele treina.', outfit: Outfit.training),
  _f(2, 'Despertar', 120, 'Uma aura branca aparece em volta do corpo.', aura: 1, outfit: Outfit.training),
  _f(3, 'Lutador', 250, 'Uniforme de luta laranja e aura azul-clara.',
      aura: 1, auraColor: 0xFFA3D4D5, outfit: Outfit.gi),
  _f(4, 'Lutador em chamas', 380, 'A aura vira fogo laranja.', aura: 2, auraColor: 0xFFFFA066, outfit: Outfit.gi),
  _f(5, 'Super Lutador', 550, 'Cabelo dourado espetado, olhos verdes e aura de fogo dourada.',
      aura: 2, auraColor: _gold, hair: Hair.spiky, hairColor: _gold, outfit: Outfit.gi, eyes: _teal),
  _f(6, 'Super Lutador 2', 800, 'Raios elétricos estalam dentro da aura.',
      aura: 2, auraColor: _gold, hair: Hair.spiky, hairColor: _gold, outfit: Outfit.gi, eyes: _teal, lightning: true),
  _f(7, 'Super Lutador 3', 1100, 'Cabelo dourado até a cintura e uma capa vermelha.',
      aura: 3,
      auraColor: _gold,
      hair: Hair.long,
      hairColor: _gold,
      outfit: Outfit.giCape,
      eyes: _teal,
      lightning: true),
  _f(8, 'Fúria Escarlate', 1500, 'Cabelo selvagem vermelho e aura cor de sangue.',
      aura: 3, auraColor: 0xFFFF5D62, hair: Hair.wild, hairColor: 0xFFE8506A, outfit: Outfit.giCape, eyes: 0xFFC34043),
  _f(9, 'Supremo Azul', 2000, 'Cabelo azul e aura azul com raios.',
      aura: 3,
      auraColor: 0xFF7FB4CA,
      hair: Hair.spiky,
      hairColor: 0xFF5FB7E8,
      outfit: Outfit.giCape,
      eyes: 0xFF7E9CD8,
      lightning: true),
  _f(10, 'Instinto Prateado', 2600, 'Cabelo prateado, roupa sagrada e calma total.',
      aura: 3, auraColor: 0xFFDCD7BA, hair: Hair.spiky, hairColor: 0xFFE4E6EE, outfit: Outfit.divine, eyes: 0xFFA3D4D5),
  _f(11, 'Chama Esmeralda', 3300, 'Cabelo em labaredas verdes e um anel de faíscas.',
      aura: 4, auraColor: 0xFF98BB6C, hair: Hair.flame, hairColor: 0xFF7DDC5A, outfit: Outfit.divine, eyes: 0xFF98BB6C),
  _f(12, 'Tempestade Violeta', 4100, 'Cabelo selvagem violeta no meio de uma tempestade de raios.',
      aura: 4,
      auraColor: 0xFF957FB8,
      hair: Hair.wild,
      hairColor: 0xFFB78CF0,
      outfit: Outfit.divine,
      eyes: 0xFFD27E99,
      lightning: true),
  _f(13, 'Sol Negro', 5000, 'Cabelo escuro em chamas, olhos vermelhos e aura negra com brasas.',
      aura: 4, auraColor: 0xFFC34043, hair: Hair.flame, hairColor: 0xFF3A3A4A, outfit: Outfit.giCape, eyes: 0xFFFF5D62),
  _f(14, 'Aurora Boreal', 6000, 'Cabelo longo rosa e uma aura dupla gigante.',
      aura: 5,
      auraColor: 0xFF6FE0C8,
      hair: Hair.long,
      hairColor: 0xFFF2A0C8,
      outfit: Outfit.divine,
      eyes: 0xFF6FE0C8,
      lightning: true),
  _f(15, 'Ultra Cósmico', 7200, 'Aura e cabelo mudam de cor como uma galáxia.',
      aura: 5, hair: Hair.flame, outfit: Outfit.divine, lightning: true, cosmic: true),
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
      power: _forms.last.power + (n - 1) * 1500,
      aura: 5,
      auraColor: hslToArgb(hue, .7, .65),
      hair: const [Hair.flame, Hair.wild, Hair.long, Hair.spiky][n % 4],
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
