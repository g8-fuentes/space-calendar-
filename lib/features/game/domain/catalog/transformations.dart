import 'passages.dart';

export 'passages.dart' show Passage;

/// Roupa do personagem, cada vez mais clara conforme a jornada.
enum Outfit { casual, shirt, tunic, robe, radiant }

/// Um nível da jornada de fé: só visual, liberado pelos pontos totais
/// (soma dos atributos). Não há último nível.
class Transformation {
  const Transformation({
    required this.index,
    required this.name,
    required this.power,
    required this.passage,
    this.aura = 0,
    this.auraColor = 0xFFFFFFFF,
    this.outfit = Outfit.casual,
    this.halo = 0,
    this.rays = false,
    this.wings = false,
    this.shimmer = false,
  });

  final int index;

  /// Nome da etapa (Buscador, Discípulo...).
  final String name;

  /// Pontos totais para liberar.
  final int power;
  final Passage passage;

  /// Força da luz: 0 = nenhuma, 1 = brilho, 2 = partículas de luz,
  /// 3 = luz forte, 4 = estrelas em volta, 5 = luz gigante.
  final int aura;
  final int auraColor;
  final Outfit outfit;

  /// Auréola: 0 = nenhuma, 1 = simples, 2 = dupla e brilhante.
  final int halo;

  /// Raios de luz descendo do céu.
  final bool rays;

  /// Asas de luz.
  final bool wings;

  /// A luz troca de tom (dourado, branco e azul-claro).
  final bool shimmer;

  int get level => index + 1;
  String get title => 'Nível $level · $name';
}

/// Etapas da jornada: a partir de qual nível (índice) cada uma começa.
const _stages = <(int, String)>[
  (0, 'Buscador'),
  (3, 'Ouvinte da Palavra'),
  (6, 'Discípulo'),
  (10, 'Servo fiel'),
  (15, 'Sal da terra'),
  (21, 'Luz do mundo'),
  (28, 'Filho amado'),
  (36, 'Abençoado'),
  (46, 'Cheio do Espírito'),
  (60, 'De glória em glória'),
];

/// Pontos a mais para passar do nível [i] - 1 para o [i].
int _stepCost(int i) => i <= 0 ? 0 : (40 + 15 * (i - 1)).clamp(40, 400);

final _power = <int>[0];
final _cache = <int, Transformation>{};

int _powerAt(int i) {
  while (_power.length <= i) {
    _power.add(_power.last + _stepCost(_power.length));
  }
  return _power[i];
}

Transformation transformationAt(int i) => _cache.putIfAbsent(i, () {
      var name = _stages.first.$2;
      for (final (from, n) in _stages) {
        if (i >= from) name = n;
      }
      return Transformation(
        index: i,
        name: name,
        power: _powerAt(i),
        passage: passages[i % passages.length],
        aura: i < 2
            ? 0
            : i < 6
                ? 1
                : i < 15
                    ? 2
                    : i < 28
                        ? 3
                        : i < 46
                            ? 4
                            : 5,
        auraColor: i < 6
            ? 0xFFFFF6D8
            : i < 15
                ? 0xFFFFE08A
                : i < 28
                    ? 0xFFFFD84A
                    : 0xFFFFF1B0,
        outfit: i < 3
            ? Outfit.casual
            : i < 6
                ? Outfit.shirt
                : i < 15
                    ? Outfit.tunic
                    : i < 28
                        ? Outfit.robe
                        : Outfit.radiant,
        halo: i < 10
            ? 0
            : i < 28
                ? 1
                : 2,
        rays: i >= 21,
        wings: i >= 36,
        shimmer: i >= 60,
      );
    });

int transformationIndexFor(int power) {
  var i = 0;
  while (transformationAt(i + 1).power <= power) {
    i++;
  }
  return i;
}
