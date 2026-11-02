import 'catalog.dart' show hslToArgb;

/// Peças extras do traje do astronauta.
enum Gear {
  /// Macacão de treino, sem mochila.
  none,

  /// Mochila de oxigênio.
  pack,

  /// Mochila a jato com chamas.
  jet,
}

/// Frase de um astronauta ou de alguém que olhou para as estrelas.
typedef Quote = ({String text, String author});

const quotes = <Quote>[
  (text: 'A Terra é azul!', author: 'Yuri Gagarin'),
  (text: 'Um pequeno passo para um homem, um salto gigante para a humanidade.', author: 'Neil Armstrong'),
  (text: 'Nós escolhemos ir à Lua não porque é fácil, mas porque é difícil.', author: 'John F. Kennedy'),
  (text: 'A Terra é o berço da humanidade, mas ninguém vive no berço para sempre.', author: 'Konstantin Tsiolkovsky'),
  (text: 'Somos feitos de matéria das estrelas.', author: 'Carl Sagan'),
  (text: 'Houston, tivemos um problema.', author: 'Jack Swigert, Apollo 13'),
  (text: 'A Águia pousou.', author: 'Neil Armstrong'),
  (text: 'Magnífica desolação.', author: 'Buzz Aldrin, na Lua'),
  (text: 'Lembre-se de olhar para as estrelas, e não para os seus pés.', author: 'Stephen Hawking'),
  (text: 'Fracassar não é uma opção.', author: 'Gene Kranz, Apollo 13'),
  (text: 'A exploração está na nossa natureza. Começamos como andarilhos, e ainda somos.', author: 'Carl Sagan'),
  (text: 'O universo não tem nenhuma obrigação de fazer sentido para você.', author: 'Neil deGrasse Tyson'),
  (text: 'Ad astra per aspera: às estrelas, por caminhos difíceis.', author: 'ditado latino'),
  (text: 'Olhe de novo para aquele ponto. É aqui. É o nosso lar.', author: 'Carl Sagan'),
  (text: 'Mantenha os olhos nas estrelas e os pés no chão.', author: 'Theodore Roosevelt'),
  (text: 'Limitar nossa atenção às coisas da Terra seria limitar o espírito humano.', author: 'Stephen Hawking'),
];

/// Um nível do astronauta: só visual, liberado pelo poder total (soma dos
/// pontos dos atributos). Cada nível traz um traje novo e uma frase, e os
/// níveis não têm fim.
class Transformation {
  const Transformation({
    required this.index,
    required this.name,
    required this.power,
    required this.description,
    this.suit = 0xFFE4DFC6,
    this.trim = 0xFFFFA066,
    this.visor = 0xFF223249,
    this.gear = Gear.pack,
    this.aura = 0,
    this.auraColor = 0xFFFFFFFF,
    this.lightning = false,
    this.cosmic = false,
  });

  final int index;
  final String name;

  /// Poder total para liberar.
  final int power;
  final String description;

  /// Cores do traje, das faixas e do visor do capacete.
  final int suit, trim, visor;
  final Gear gear;

  /// Força da aura: 0 = nenhuma, 1 = brilho, 2 = chamas, 3 = chamas fortes,
  /// 4 = com anel de faíscas, 5 = chama dupla gigante.
  final int aura;
  final int auraColor;

  /// Raios em volta do corpo.
  final bool lightning;

  /// Cores mudando sem parar.
  final bool cosmic;

  int get level => index + 1;
  String get title => 'Nível $level · $name';
  Quote get quote => quotes[index % quotes.length];
}

const _gold = 0xFFFFD84A, _goldVisor = 0xFFC0A36E;

const _forms = <Transformation>[
  Transformation(
      index: 0,
      name: 'Cadete espacial',
      power: 0,
      description: 'Macacão laranja de treino e o primeiro capacete.',
      suit: 0xFFFFA066,
      trim: 0xFF223249,
      gear: Gear.none),
  Transformation(
      index: 1, name: 'Astronauta em treino', power: 40, description: 'Traje branco de verdade e mochila de oxigênio.'),
  Transformation(
      index: 2,
      name: 'Astronauta',
      power: 120,
      description: 'Pronto para a primeira caminhada no espaço: uma luz branca em volta do traje.',
      aura: 1),
  Transformation(
      index: 3,
      name: 'Especialista de missão',
      power: 250,
      description: 'Faixas azuis no traje e brilho azul-claro.',
      trim: 0xFF7E9CD8,
      aura: 1,
      auraColor: 0xFFA3D4D5),
  Transformation(
      index: 4,
      name: 'Piloto',
      power: 380,
      description: 'Visor dourado e mochila a jato acesa.',
      trim: 0xFF7E9CD8,
      visor: _goldVisor,
      gear: Gear.jet,
      aura: 2,
      auraColor: 0xFFFFA066),
  Transformation(
      index: 5,
      name: 'Comandante',
      power: 550,
      description: 'Faixas vermelhas de comando e aura dourada.',
      trim: 0xFFC34043,
      visor: _goldVisor,
      gear: Gear.jet,
      aura: 2,
      auraColor: _gold),
  Transformation(
      index: 6,
      name: 'Caminhante espacial',
      power: 800,
      description: 'Raios de energia estalam em volta do traje.',
      trim: 0xFFC34043,
      visor: _goldVisor,
      gear: Gear.jet,
      aura: 2,
      auraColor: _gold,
      lightning: true),
  Transformation(
      index: 7,
      name: 'Capitão da frota',
      power: 1100,
      description: 'Traje dourado de capitão e chamas fortes.',
      suit: 0xFFE6C384,
      trim: 0xFFC34043,
      visor: 0xFF223249,
      gear: Gear.jet,
      aura: 3,
      auraColor: _gold,
      lightning: true),
  Transformation(
      index: 8,
      name: 'Explorador interestelar',
      power: 1500,
      description: 'Traje azul-noite e aura azul das estrelas vizinhas.',
      suit: 0xFF2D4F67,
      trim: 0xFF7FB4CA,
      visor: 0xFF7FB4CA,
      gear: Gear.jet,
      aura: 3,
      auraColor: 0xFF7FB4CA),
  Transformation(
      index: 9,
      name: 'Almirante estelar',
      power: 2000,
      description: 'Traje vermelho, visor dourado e raios.',
      suit: 0xFFC34043,
      trim: 0xFFE6C384,
      visor: _goldVisor,
      gear: Gear.jet,
      aura: 3,
      auraColor: 0xFFFF5D62,
      lightning: true),
  Transformation(
      index: 10,
      name: 'Guardião da galáxia',
      power: 2600,
      description: 'Traje prateado e uma calma total.',
      suit: 0xFFE4E6EE,
      trim: 0xFF938AA9,
      visor: 0xFFA3D4D5,
      gear: Gear.jet,
      aura: 3,
      auraColor: 0xFFDCD7BA),
  Transformation(
      index: 11,
      name: 'Viajante de nebulosas',
      power: 3300,
      description: 'Traje verde-água e um anel de faíscas.',
      suit: 0xFF6A9589,
      trim: 0xFF98BB6C,
      visor: 0xFF98BB6C,
      gear: Gear.jet,
      aura: 4,
      auraColor: 0xFF98BB6C),
  Transformation(
      index: 12,
      name: 'Senhor do hiperespaço',
      power: 4100,
      description: 'Traje violeta no meio de uma tempestade de raios.',
      suit: 0xFF957FB8,
      trim: 0xFFD27E99,
      visor: 0xFFD27E99,
      gear: Gear.jet,
      aura: 4,
      auraColor: 0xFF957FB8,
      lightning: true),
  Transformation(
      index: 13,
      name: 'Domador de buracos negros',
      power: 5000,
      description: 'Traje negro, visor vermelho e aura escura com brasas.',
      suit: 0xFF363646,
      trim: 0xFFFF5D62,
      visor: 0xFFC34043,
      gear: Gear.jet,
      aura: 4,
      auraColor: 0xFFC34043),
  Transformation(
      index: 14,
      name: 'Lenda da aurora',
      power: 6000,
      description: 'Traje rosa e uma aura dupla gigante, como uma aurora.',
      suit: 0xFFF2A0C8,
      trim: 0xFF6FE0C8,
      visor: 0xFF6FE0C8,
      gear: Gear.jet,
      aura: 5,
      auraColor: 0xFF6FE0C8,
      lightning: true),
  Transformation(
      index: 15,
      name: 'Astronauta cósmico',
      power: 7200,
      description: 'Aura e visor mudam de cor como uma galáxia.',
      gear: Gear.jet,
      aura: 5,
      lightning: true,
      cosmic: true),
];

final _cache = <int, Transformation>{};

/// Nível [i]. Depois do Astronauta cósmico, um novo nível a cada 1.500
/// pontos, sem fim.
Transformation transformationAt(int i) {
  if (i < _forms.length) return _forms[i];
  return _cache.putIfAbsent(i, () {
    final n = i - _forms.length + 2;
    final hue = (i * 47 % 360).toDouble();
    return Transformation(
      index: i,
      name: 'Astronauta cósmico $n',
      power: _forms.last.power + (n - 1) * 1500,
      suit: hslToArgb(hue, .35, .8),
      trim: hslToArgb((hue + 120) % 360, .6, .6),
      gear: Gear.jet,
      aura: 5,
      auraColor: hslToArgb(hue, .7, .65),
      lightning: true,
      cosmic: true,
      description: 'Mais um nível de poder cósmico. A jornada não tem fim.',
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
