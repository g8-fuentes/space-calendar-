import 'catalog.dart' show hslToArgb;

/// Penteado do personagem.
enum Hair { normal, spiky, wild, long, flame }

/// Roupa do dev: camiseta, moletom, macacão de voo, macacão com capa de
/// comandante e traje cósmico.
enum Outfit { casual, training, gi, giCape, starSuit }

/// Frase de um dev ou de um explorador do espaço.
typedef Quote = ({String text, String author});

const quotes = <Quote>[
  (text: 'Talk is cheap. Show me the code.', author: 'Linus Torvalds'),
  (text: 'Nós escolhemos ir à Lua não porque é fácil, mas porque é difícil.', author: 'John F. Kennedy'),
  (text: 'Primeiro resolva o problema. Depois escreva o código.', author: 'John Johnson'),
  (text: 'A Terra é azul!', author: 'Yuri Gagarin'),
  (text: 'Faça funcionar, faça certo, faça rápido.', author: 'Kent Beck'),
  (text: 'A Terra é o berço da humanidade, mas ninguém vive no berço para sempre.', author: 'Konstantin Tsiolkovsky'),
  (
    text: 'Qualquer tolo escreve código que um computador entende. Bons programadores escrevem código que humanos '
        'entendem.',
    author: 'Martin Fowler'
  ),
  (text: 'Somos feitos de matéria das estrelas.', author: 'Carl Sagan'),
  (text: 'A simplicidade é pré-requisito para a confiabilidade.', author: 'Edsger Dijkstra'),
  (text: 'Um pequeno passo para um homem, um salto gigante para a humanidade.', author: 'Neil Armstrong'),
  (text: 'A melhor maneira de prever o futuro é inventá-lo.', author: 'Alan Kay'),
  (text: 'Houston, tivemos um problema.', author: 'Jack Swigert, Apollo 13'),
  (text: 'Otimização prematura é a raiz de todo mal.', author: 'Donald Knuth'),
  (text: 'Lembre-se de olhar para as estrelas, e não para os seus pés.', author: 'Stephen Hawking'),
  (
    text: 'Só existem duas coisas difíceis na computação: invalidar cache e dar nome às coisas.',
    author: 'Phil Karlton'
  ),
  (text: 'Ad astra per aspera: às estrelas, por caminhos difíceis.', author: 'ditado latino'),
  (text: 'Depurar é duas vezes mais difícil do que escrever o código.', author: 'Brian Kernighan'),
  (text: 'O futuro já chegou. Só não está bem distribuído.', author: 'William Gibson'),
  (text: 'Simples é melhor que complexo.', author: 'The Zen of Python'),
  (text: 'Código é como humor: se você precisa explicar, é ruim.', author: 'Cory House'),
  (
    text: 'Programas devem ser escritos para pessoas lerem, e só por acaso para máquinas executarem.',
    author: 'Abelson e Sussman'
  ),
  (text: 'Commit cedo, commit sempre.', author: 'ditado dev'),
  (text: 'Funciona na minha máquina.', author: 'todo dev, um dia'),
];

/// Um nível do dev: só visual, liberado pelo poder total (soma dos pontos
/// dos atributos). Cada nível traz uma frase, e os níveis não têm fim.
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

  int get level => index + 1;
  String get title => 'Nível $level · $name';
  Quote get quote => quotes[index % quotes.length];
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
  _f(0, 'Estagiário', 0, 'Camiseta com </>, jeans e uma agenda cheia de missões.'),
  _f(1, 'Dev Júnior', 40, 'Moletom de hackathon: entre um commit e outro, ele treina.', outfit: Outfit.training),
  _f(2, 'Dev Pleno', 120, 'Modo foco ligado: uma aura branca aparece em volta do corpo.',
      aura: 1, outfit: Outfit.training),
  _f(3, 'Dev Sênior', 250, 'Macacão laranja de voo e aura azul-clara.',
      aura: 1, auraColor: 0xFFA3D4D5, outfit: Outfit.gi),
  _f(4, 'Tech Lead', 380, 'A aura vira fogo laranja, como o motor de um foguete.',
      aura: 2, auraColor: 0xFFFFA066, outfit: Outfit.gi),
  _f(5, 'Staff Engineer', 550, 'Cabelo dourado espetado, olhos verdes e aura de fogo dourada.',
      aura: 2, auraColor: _gold, hair: Hair.spiky, hairColor: _gold, outfit: Outfit.gi, eyes: _teal),
  _f(6, 'Principal Engineer', 800, 'Raios elétricos estalam dentro da aura: deploy em produção.',
      aura: 2, auraColor: _gold, hair: Hair.spiky, hairColor: _gold, outfit: Outfit.gi, eyes: _teal, lightning: true),
  _f(7, 'Arquiteto de Software', 1100, 'Cabelo dourado até a cintura e capa vermelha de comandante.',
      aura: 3,
      auraColor: _gold,
      hair: Hair.long,
      hairColor: _gold,
      outfit: Outfit.giCape,
      eyes: _teal,
      lightning: true),
  _f(8, 'Hacker Escarlate', 1500, 'Cabelo selvagem vermelho e aura cor de sangue.',
      aura: 3, auraColor: 0xFFFF5D62, hair: Hair.wild, hairColor: 0xFFE8506A, outfit: Outfit.giCape, eyes: 0xFFC34043),
  _f(9, 'Distinguished Engineer', 2000, 'Cabelo azul e aura azul com raios.',
      aura: 3,
      auraColor: 0xFF7FB4CA,
      hair: Hair.spiky,
      hairColor: 0xFF5FB7E8,
      outfit: Outfit.giCape,
      eyes: 0xFF7E9CD8,
      lightning: true),
  _f(10, 'Fellow', 2600, 'Cabelo prateado, traje cósmico e calma total.',
      aura: 3,
      auraColor: 0xFFDCD7BA,
      hair: Hair.spiky,
      hairColor: 0xFFE4E6EE,
      outfit: Outfit.starSuit,
      eyes: 0xFFA3D4D5),
  _f(11, 'Mestre do Kernel', 3300, 'Cabelo em labaredas verdes e um anel de faíscas.',
      aura: 4,
      auraColor: 0xFF98BB6C,
      hair: Hair.flame,
      hairColor: 0xFF7DDC5A,
      outfit: Outfit.starSuit,
      eyes: 0xFF98BB6C),
  _f(12, 'Lenda do Open Source', 4100, 'Cabelo selvagem violeta no meio de uma tempestade de raios.',
      aura: 4,
      auraColor: 0xFF957FB8,
      hair: Hair.wild,
      hairColor: 0xFFB78CF0,
      outfit: Outfit.starSuit,
      eyes: 0xFFD27E99,
      lightning: true),
  _f(13, 'Dev Buraco Negro', 5000, 'Cabelo escuro em chamas, olhos vermelhos e aura negra com brasas.',
      aura: 4, auraColor: 0xFFC34043, hair: Hair.flame, hairColor: 0xFF3A3A4A, outfit: Outfit.giCape, eyes: 0xFFFF5D62),
  _f(14, 'Arquiteto do Cosmos', 6000, 'Cabelo longo rosa e uma aura dupla gigante, como uma aurora.',
      aura: 5,
      auraColor: 0xFF6FE0C8,
      hair: Hair.long,
      hairColor: 0xFFF2A0C8,
      outfit: Outfit.starSuit,
      eyes: 0xFF6FE0C8,
      lightning: true),
  _f(15, 'Dev Cósmico', 7200, 'Aura e cabelo mudam de cor como uma galáxia.',
      aura: 5, hair: Hair.flame, outfit: Outfit.starSuit, lightning: true, cosmic: true),
];

final _cache = <int, Transformation>{};

/// Nível [i]. Depois do Dev Cósmico, um novo nível a cada 1.500 pontos, sem fim.
Transformation transformationAt(int i) {
  if (i < _forms.length) return _forms[i];
  return _cache.putIfAbsent(i, () {
    final n = i - _forms.length + 2;
    final hue = (i * 47 % 360).toDouble();
    return Transformation(
      index: i,
      name: 'Dev Cósmico $n',
      power: _forms.last.power + (n - 1) * 1500,
      aura: 5,
      auraColor: hslToArgb(hue, .7, .65),
      hair: const [Hair.flame, Hair.wild, Hair.long, Hair.spiky][n % 4],
      hairColor: hslToArgb(hue, .7, .7),
      outfit: Outfit.starSuit,
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
