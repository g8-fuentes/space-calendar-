import 'dart:math' as math;

import 'catalog.dart' show hslToArgb;

enum BodyKind { earth, moon, rocky, belt, gas, ring, star }

/// Um destino da jornada. Os 11 primeiros são reais; depois de
/// Proxima Centauri os mundos são gerados sem fim a partir do índice.
class Destination {
  const Destination({
    required this.index,
    required this.name,
    required this.xpRequired,
    required this.kind,
    required this.colors,
    required this.fact,
  });

  final int index;
  final String name;
  final int xpRequired;
  final BodyKind kind;
  final List<int> colors;
  final String fact;
}

const _base = <(String, int, BodyKind, List<int>, String)>[
  ('Terra', 0, BodyKind.earth, [0xFF7E9CD8, 0xFF98BB6C],
      'Base de lançamento. É o único planeta conhecido com vida.'),
  ('Lua', 300, BodyKind.moon, [0xFF938AA9, 0xFF727169],
      'Fica a cerca de 384 mil km da Terra.'),
  ('Marte', 900, BodyKind.rocky, [0xFFE46876, 0xFFFFA066],
      'Tem o Monte Olimpo, o maior vulcão conhecido do Sistema Solar.'),
  ('Cinturão de Asteroides', 1800, BodyKind.belt, [0xFF727169, 0xFFC0A36E],
      'Fica entre Marte e Júpiter. Ceres é o maior objeto dele.'),
  ('Júpiter', 3200, BodyKind.gas, [0xFFC0A36E, 0xFFDCD7BA, 0xFFE46876],
      'É o maior planeta. A Grande Mancha Vermelha é uma tempestade maior que a Terra.'),
  ('Saturno', 5000, BodyKind.ring, [0xFFE6C384, 0xFFC0A36E],
      'Seus anéis são feitos principalmente de gelo e rocha.'),
  ('Urano', 7500, BodyKind.gas, [0xFFA3D4D5, 0xFF7FB4CA],
      'Gira deitado, com o eixo inclinado cerca de 98 graus.'),
  ('Netuno', 10500, BodyKind.gas, [0xFF7E9CD8, 0xFF2D4F67],
      'Tem os ventos mais rápidos já medidos no Sistema Solar.'),
  ('Plutão', 14000, BodyKind.moon, [0xFFC8C093, 0xFFDCD7BA],
      'Planeta anão com uma grande planície de gelo em forma de coração.'),
  ('Nuvem de Oort', 18500, BodyKind.belt, [0xFFA3D4D5, 0xFFDCD7BA],
      'Região distante de corpos gelados, provável origem de cometas de longo período.'),
  ('Proxima Centauri', 24000, BodyKind.star, [0xFFE46876, 0xFFFFA066],
      'A estrela mais próxima do Sol, a cerca de 4,2 anos-luz.'),
];

const _prefixes = [
  'Kepler', 'Gliese', 'Trappist', 'Vega', 'Lyra', 'Orion',
  'Draco', 'Cygnus', 'Nova', 'Zeta', 'Altair', 'Rigel',
];

const _generatedKinds = [
  BodyKind.rocky, BodyKind.gas, BodyKind.ring,
  BodyKind.moon, BodyKind.belt, BodyKind.star,
];

int seedHash(int n) {
  var h = (n * 2654435761) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 1274126177) & 0xFFFFFFFF;
  return h;
}

/// XP necessário para o destino [index]. Cresce 12% a cada novo mundo
/// gerado, então a jornada nunca termina mas também nunca trava.
int _generatedXp(int j) =>
    (24000 + 6000 * (math.pow(1.12, j) - 1) / 0.12).round();

Destination destinationAt(int index) {
  if (index < _base.length) {
    final b = _base[index];
    return Destination(
      index: index,
      name: b.$1,
      xpRequired: b.$2,
      kind: b.$3,
      colors: b.$4,
      fact: b.$5,
    );
  }
  final j = index - _base.length + 1;
  final h = seedHash(index);
  final h1 = (h % 360).toDouble();
  final h2 = ((h1 + 40 + (h >> 9) % 80) % 360).toDouble();
  final letter = 'abcdef'[(h >> 12) % 6];
  return Destination(
    index: index,
    name: '${_prefixes[h % _prefixes.length]}-${100 + (h >> 4) % 900}$letter',
    xpRequired: _generatedXp(j),
    kind: _generatedKinds[(h >> 16) % _generatedKinds.length],
    colors: [
      hslToArgb(h1, 0.45, 0.62),
      hslToArgb(h2, 0.40, 0.50),
      hslToArgb((h1 + 180) % 360, 0.45, 0.60),
    ],
    fact: 'Mundo descoberto no setor ${j ~/ 10 + 1}. '
        'Destino número ${index + 1} da jornada.',
  );
}

/// Índice do destino mais distante já alcançado com [xp].
int destinationIndexFor(int xp) {
  var i = 0;
  while (destinationAt(i + 1).xpRequired <= xp) {
    i++;
  }
  return i;
}
