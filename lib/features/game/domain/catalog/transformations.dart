import 'catalog.dart' show hslToArgb;

/// Acessórios do dev: no nível 1 só o moletom; no 2 os fones; do 5 em
/// diante o notebook aberto.
enum Gear { none, pack, jet }

/// Frase de um nível.
typedef Quote = ({String text, String author});

const quotes = <Quote>[
  (text: 'Falar é fácil. Mostre-me o código.', author: 'Linus Torvalds'),
  (text: 'Primeiro resolva o problema. Depois escreva o código.', author: 'John Johnson'),
  (
    text:
        'Qualquer um escreve código que um computador entende. Bons programadores escrevem código que pessoas entendem.',
    author: 'Martin Fowler'
  ),
  (text: 'Simplicidade é pré-requisito para confiabilidade.', author: 'Edsger Dijkstra'),
  (text: 'A melhor forma de prever o futuro é inventá-lo.', author: 'Alan Kay'),
  (text: 'Otimização prematura é a raiz de todo mal.', author: 'Donald Knuth'),
  (text: 'Funciona na minha máquina.', author: 'todo dev, um dia'),
  (text: 'É mais fácil pedir desculpas do que pedir permissão.', author: 'Grace Hopper'),
  (text: 'Debugar é duas vezes mais difícil do que escrever o código.', author: 'Brian Kernighan'),
  (text: 'Bom código é a sua própria melhor documentação.', author: 'Steve McConnell'),
  (
    text: 'Programas devem ser escritos para pessoas lerem, e só por acaso para máquinas executarem.',
    author: 'Harold Abelson'
  ),
  (text: 'Há 10 tipos de pessoas: as que entendem binário e as que não entendem.', author: 'piada de programador'),
  (
    text: 'Só podemos ver um pouco do futuro, mas o suficiente para perceber que há muito a fazer.',
    author: 'Alan Turing'
  ),
  (
    text: 'Programe como se quem vai manter seu código fosse alguém muito bravo que sabe onde você mora.',
    author: 'John Woods'
  ),
  (text: 'Hello, world!', author: 'Brian Kernighan'),
  (text: 'Talk is cheap. Show me the code.', author: 'Linus Torvalds'),
];

/// Um nível do dev: só visual, liberado pelo poder total (soma dos pontos
/// dos atributos). Cada nível traz roupa, acessórios e aura novos e uma
/// frase, e os níveis não têm fim.
class Transformation {
  const Transformation({
    required this.index,
    required this.name,
    required this.power,
    required this.description,
    this.suit = 0xFF3A3F4A,
    this.trim = 0xFF3CFF6B,
    this.pants = 0xFF223249,
    this.gear = Gear.none,
    this.aura = 0,
    this.auraColor = 0xFFFFFFFF,
    this.lightning = false,
    this.cosmic = false,
    this.shades = false,
  });

  final int index;
  final String name;

  /// Poder total para liberar.
  final int power;
  final String description;

  /// Cores do moletom, dos detalhes e da calça.
  final int suit, trim, pants;
  final Gear gear;

  /// Força da aura: 0 = nenhuma, 1 = brilho, 2 = chamas, 3 = chamas fortes,
  /// 4 = com anel de faíscas, 5 = chama dupla gigante.
  final int aura;
  final int auraColor;

  /// Raios em volta do corpo.
  final bool lightning;

  /// Cores mudando sem parar.
  final bool cosmic;

  /// Óculos escuros de quem enxerga a Matrix.
  final bool shades;

  int get level => index + 1;
  String get title => 'Nível $level · $name';
  Quote get quote => quotes[index % quotes.length];
}

const _gold = 0xFFFFD84A, _matrix = 0xFF3CFF6B;

/// (nome, pontos, descrição, moletom, detalhe, aura, cor da aura, raios)
typedef _L = (String, int, String, int?, int?, int, int, bool);

const _levels = <_L>[
  ('Visitante (guest)', 0, 'Moletom com capuz e um terminal piscando.', null, null, 0, 0xFFFFFFFF, false),
  ('Estagiário no terminal', 40, 'Fones de ouvido para o foco total.', null, null, 0, 0xFFFFFFFF, false),
  ('Dev júnior', 120, 'O primeiro brilho verde em volta do corpo.', null, null, 1, _matrix, false),
  ('Dev pleno', 250, 'Detalhes azuis e brilho azul-claro.', null, 0xFF7E9CD8, 1, 0xFFA3D4D5, false),
  (
    'Dev sênior',
    380,
    'Notebook aberto com código brilhando e as primeiras chamas.',
    null,
    0xFF7E9CD8,
    2,
    _matrix,
    false
  ),
  ('Tech lead', 550, 'Detalhes vermelhos e aura dourada.', null, 0xFFC34043, 2, _gold, false),
  ('Hacker do terminal', 800, 'Óculos escuros e raios de energia em volta.', 0xFF16161D, _matrix, 2, _matrix, true),
  ('Root', 1100, 'Moletom dourado e chamas fortes: acesso total.', 0xFFE6C384, 0xFFC34043, 3, _gold, true),
  ('Arquiteto de sistemas', 1500, 'Moletom azul-noite e aura azul.', 0xFF2D4F67, 0xFF7FB4CA, 3, 0xFF7FB4CA, false),
  ('Mestre do kernel', 2000, 'Moletom vermelho e raios.', 0xFFC34043, 0xFFE6C384, 3, 0xFFFF5D62, true),
  ('Operador da Matrix', 2600, 'Roupa prateada e uma calma total.', 0xFFE4E6EE, 0xFF938AA9, 3, 0xFFDCD7BA, false),
  ('Desperto', 3300, 'Roupa verde-código e um anel de faíscas.', 0xFF1E5A2E, _matrix, 4, _matrix, false),
  (
    'Quebrador de código',
    4100,
    'Roupa violeta no meio de uma tempestade de raios.',
    0xFF957FB8,
    0xFFD27E99,
    4,
    0xFF957FB8,
    true
  ),
  ('Senhor dos bits', 5000, 'Roupa negra e aura escura com brasas.', 0xFF0A0E0A, 0xFFFF5D62, 4, 0xFFC34043, false),
  (
    'Arquiteto da Matrix',
    6000,
    'Roupa branca e uma aura dupla gigante de código.',
    0xFFF2F2F2,
    _matrix,
    5,
    _matrix,
    true
  ),
  (
    'O Escolhido',
    7200,
    'Você enxerga o código por trás de tudo: aura e cores mudam sem parar.',
    null,
    null,
    5,
    0xFFFFFFFF,
    true
  ),
];

final _cache = <int, Transformation>{};

/// Nível [i]. Depois do último nível com nome, um novo nível a cada 1.500
/// pontos, sem fim.
Transformation transformationAt(int i) => _cache.putIfAbsent(i, () {
      if (i < _levels.length) {
        final (name, power, desc, suit, trim, aura, auraColor, lightning) = _levels[i];
        return Transformation(
          index: i,
          name: name,
          power: power,
          description: desc,
          suit: suit ?? 0xFF3A3F4A,
          trim: trim ?? _matrix,
          gear: i == 0
              ? Gear.none
              : i < 4
                  ? Gear.pack
                  : Gear.jet,
          aura: aura,
          auraColor: auraColor,
          lightning: lightning,
          cosmic: i == _levels.length - 1,
          shades: i >= 6,
        );
      }
      final n = i - _levels.length + 2;
      final hue = (i * 47 % 360).toDouble();
      return Transformation(
        index: i,
        name: 'O Escolhido $n',
        power: _levels.last.$2 + (n - 1) * 1500,
        suit: hslToArgb(hue, .35, .3),
        trim: hslToArgb((hue + 120) % 360, .6, .6),
        gear: Gear.jet,
        aura: 5,
        auraColor: hslToArgb(hue, .7, .65),
        lightning: true,
        cosmic: true,
        shades: true,
        description: 'Mais um nível dentro da Matrix. A jornada não tem fim.',
      );
    });

int transformationIndexFor(int power) {
  var i = 0;
  while (transformationAt(i + 1).power <= power) {
    i++;
  }
  return i;
}

int get namedTransformations => _levels.length;
