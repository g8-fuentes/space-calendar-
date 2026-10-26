import 'dart:math' as math;

import 'catalog.dart' show hslToArgb;

/// As três fases da exploração.
enum Region { earth, solar, deep }

/// Como o lugar é desenhado.
enum PlaceKind { city, earth, moon, rocky, gas, ring, star, constellation }

/// Monumento desenhado no horizonte de uma cidade.
enum Landmark { none, christ, cityTower, needle, ironTower, clockTower, coliseum, pyramids, onionDome, pagoda, dome, opera, obelisk }

String regionName(Region r) => switch (r) {
      Region.earth => 'Terra',
      Region.solar => 'Sistema Solar',
      Region.deep => 'Espaço profundo',
    };

class Place {
  const Place({
    required this.index,
    required this.name,
    required this.region,
    required this.kind,
    required this.colors,
    required this.fact,
    required this.missionsRequired,
    this.landmark = Landmark.none,
    this.stars = const [],
    this.lines = const [],
  });

  final int index;
  final String name;
  final Region region;
  final PlaceKind kind;
  final List<int> colors;
  final String fact;

  /// Missões concluídas (no total) para chegar aqui.
  final int missionsRequired;
  final Landmark landmark;

  /// Constelação: estrelas (x, y de 0 a 1, brilho 1 a 3) e ligações.
  final List<(double, double, int)> stars;
  final List<(int, int)> lines;
}

typedef _P = (String, PlaceKind, List<int>, String, Landmark);

const _cities = <_P>[
  ('Bauru, SP', PlaceKind.city, [0xFFFFA066], 'Ponto de partida. Terra do sanduíche bauru e da Ferrovia Noroeste.', Landmark.obelisk),
  ('São Paulo', PlaceKind.city, [0xFF7E9CD8], 'A maior cidade da América do Sul, com mais de 12 milhões de pessoas.', Landmark.cityTower),
  ('Rio de Janeiro', PlaceKind.city, [0xFF98BB6C], 'O Cristo Redentor olha a cidade do alto do Corcovado, a 700 m.', Landmark.christ),
  ('Buenos Aires', PlaceKind.city, [0xFFA3D4D5], 'O Obelisco da Avenida 9 de Julho tem 67 metros.', Landmark.obelisk),
  ('Cidade do México', PlaceKind.city, [0xFF98BB6C], 'Construída sobre o antigo lago de Tenochtitlan, a 2.240 m de altitude.', Landmark.pyramids),
  ('Nova York', PlaceKind.city, [0xFF7E9CD8], 'Mais de 800 línguas são faladas na cidade.', Landmark.needle),
  ('Londres', PlaceKind.city, [0xFFC34043], 'O Big Ben é o sino; a torre se chama Elizabeth Tower.', Landmark.clockTower),
  ('Paris', PlaceKind.city, [0xFFD27E99], 'A Torre Eiffel cresce até 15 cm no verão por causa do calor.', Landmark.ironTower),
  ('Roma', PlaceKind.city, [0xFFFFA066], 'O Coliseu recebia até 50 mil pessoas.', Landmark.coliseum),
  ('Cairo', PlaceKind.city, [0xFFE6C384], 'A Grande Pirâmide foi a construção mais alta do mundo por 3.800 anos.', Landmark.pyramids),
  ('Moscou', PlaceKind.city, [0xFFC34043], 'As cúpulas em forma de cebola da Catedral de São Basílio são do século 16.', Landmark.onionDome),
  ('Dubai', PlaceKind.city, [0xFFE6C384], 'O Burj Khalifa tem 828 m, o prédio mais alto do mundo.', Landmark.needle),
  ('Mumbai', PlaceKind.city, [0xFF957FB8], 'Bollywood, em Mumbai, lança mais filmes por ano que Hollywood.', Landmark.dome),
  ('Pequim', PlaceKind.city, [0xFFC34043], 'A Cidade Proibida tem cerca de 980 construções.', Landmark.pagoda),
  ('Tóquio', PlaceKind.city, [0xFFFF5D62], 'A região de Tóquio é a área urbana mais populosa do planeta.', Landmark.ironTower),
  ('Sydney', PlaceKind.city, [0xFF7FB4CA], 'As "velas" da Ópera de Sydney são cobertas por mais de 1 milhão de azulejos.', Landmark.opera),
];

const _solar = <_P>[
  ('Órbita da Terra', PlaceKind.earth, [0xFF7E9CD8, 0xFF98BB6C], 'A 400 km de altura, a Estação Espacial dá uma volta na Terra a cada 90 minutos.', Landmark.none),
  ('Lua', PlaceKind.moon, [0xFF938AA9, 0xFF727169], 'Fica a 384 mil km. A luz dela leva 1,3 segundo para chegar aqui.', Landmark.none),
  ('Vênus', PlaceKind.rocky, [0xFFE6C384, 0xFFC0A36E], 'O planeta mais quente: 465 °C, mesmo sem ser o mais perto do Sol.', Landmark.none),
  ('Mercúrio', PlaceKind.moon, [0xFF727169, 0xFF54546D], 'Um ano em Mercúrio dura só 88 dias.', Landmark.none),
  ('Marte', PlaceKind.rocky, [0xFFFFA066, 0xFFC34043], 'Tem o Monte Olimpo, vulcão três vezes mais alto que o Everest.', Landmark.none),
  ('Fobos', PlaceKind.moon, [0xFF727169, 0xFF54546D], 'Lua de Marte que se aproxima dele 2 m a cada século.', Landmark.none),
  ('Deimos', PlaceKind.moon, [0xFF938AA9, 0xFF727169], 'A menor lua de Marte, com só 12 km de largura.', Landmark.none),
  ('Ceres', PlaceKind.moon, [0xFF938AA9, 0xFFDCD7BA], 'Planeta anão no cinturão de asteroides, com manchas de sal brilhante.', Landmark.none),
  ('Júpiter', PlaceKind.gas, [0xFFFFA066, 0xFFE6C384, 0xFFC0A36E], 'Caberiam 1.300 Terras dentro dele.', Landmark.none),
  ('Io', PlaceKind.rocky, [0xFFE6C384, 0xFFFFA066], 'O lugar com mais vulcões ativos do Sistema Solar.', Landmark.none),
  ('Europa', PlaceKind.moon, [0xFFDCD7BA, 0xFFC0A36E], 'Esconde um oceano de água salgada debaixo do gelo.', Landmark.none),
  ('Ganimedes', PlaceKind.moon, [0xFF938AA9, 0xFFC8C093], 'A maior lua do Sistema Solar, maior que Mercúrio.', Landmark.none),
  ('Calisto', PlaceKind.moon, [0xFF54546D, 0xFF938AA9], 'A superfície com mais crateras que se conhece.', Landmark.none),
  ('Saturno', PlaceKind.ring, [0xFFE6C384, 0xFFC8C093], 'É tão leve que boiaria numa banheira gigante.', Landmark.none),
  ('Titã', PlaceKind.rocky, [0xFFFFA066, 0xFFE6C384], 'Tem rios e lagos, só que de metano.', Landmark.none),
  ('Encélado', PlaceKind.moon, [0xFFDCD7BA, 0xFFA3D4D5], 'Solta jatos de água gelada para o espaço.', Landmark.none),
  ('Urano', PlaceKind.gas, [0xFFA3D4D5, 0xFF7FB4CA], 'Gira deitado, quase de lado em relação ao Sol.', Landmark.none),
  ('Titânia', PlaceKind.moon, [0xFF938AA9, 0xFF727169], 'A maior lua de Urano, com cânions de centenas de km.', Landmark.none),
  ('Netuno', PlaceKind.gas, [0xFF7E9CD8, 0xFF223249], 'Tem os ventos mais rápidos: até 2.100 km/h.', Landmark.none),
  ('Tritão', PlaceKind.moon, [0xFFD27E99, 0xFFDCD7BA], 'Gira ao contrário de Netuno e tem gêiseres de nitrogênio.', Landmark.none),
  ('Plutão', PlaceKind.moon, [0xFFC0A36E, 0xFFDCD7BA], 'Tem um coração de gelo de nitrogênio com 1.600 km.', Landmark.none),
  ('Caronte', PlaceKind.moon, [0xFF727169, 0xFFC34043], 'Tão grande perto de Plutão que os dois giram em volta de um ponto entre eles.', Landmark.none),
  ('Éris', PlaceKind.moon, [0xFFDCD7BA, 0xFF938AA9], 'Planeta anão no fim do Sistema Solar; uma volta no Sol leva 557 anos.', Landmark.none),
];

typedef _D = (String, PlaceKind, List<int>, String, List<(double, double, int)>, List<(int, int)>);

const _deep = <_D>[
  ('Alfa Centauri', PlaceKind.star, [0xFFE6C384, 0xFFFFA066], 'O sistema de estrelas mais perto do Sol, a 4,4 anos-luz.', [], []),
  ('Cruzeiro do Sul', PlaceKind.constellation, [0xFFDCD7BA], 'A constelação da bandeira do Brasil. Aponta para o polo sul celeste.',
      [(.5, .08, 3), (.5, .92, 3), (.12, .45, 2), (.86, .4, 2), (.64, .62, 1)], [(0, 1), (2, 3)]),
  ('Sirius', PlaceKind.star, [0xFFA3D4D5, 0xFFDCD7BA], 'A estrela mais brilhante do céu noturno.', [], []),
  ('Órion', PlaceKind.constellation, [0xFF7FB4CA], 'O caçador. As Três Marias são o cinturão dele.',
      [(.5, .03, 1), (.25, .18, 3), (.72, .2, 2), (.4, .5, 2), (.5, .48, 2), (.6, .46, 2), (.3, .88, 2), (.76, .84, 3)],
      [(0, 1), (0, 2), (1, 3), (2, 5), (3, 4), (4, 5), (3, 6), (5, 7)]),
  ('Betelgeuse', PlaceKind.star, [0xFFFF5D62, 0xFFFFA066], 'Supergigante vermelha: se estivesse no lugar do Sol, engoliria Júpiter.', [], []),
  ('Escorpião', PlaceKind.constellation, [0xFFFF5D62],
      'Tem a forma de um escorpião, com Antares como coração.',
      [(.12, .1, 2), (.08, .28, 2), (.2, .2, 2), (.34, .32, 3), (.44, .48, 2), (.5, .64, 2), (.56, .8, 2), (.72, .9, 2), (.88, .84, 2), (.92, .68, 2), (.82, .6, 1)],
      [(0, 2), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10)]),
  ('Antares', PlaceKind.star, [0xFFFF5D62, 0xFFC34043], 'O coração do Escorpião, 700 vezes maior que o Sol.', [], []),
  ('Plêiades', PlaceKind.constellation, [0xFFA3D4D5], 'As Sete Irmãs: um aglomerado de estrelas jovens.',
      [(.3, .3, 3), (.48, .22, 2), (.58, .36, 3), (.4, .48, 2), (.62, .54, 2), (.74, .4, 2), (.5, .66, 1)], []),
  ('Ursa Maior', PlaceKind.constellation, [0xFFDCD7BA], 'Suas sete estrelas formam a "Grande Concha".',
      [(.04, .3, 2), (.24, .24, 2), (.42, .32, 2), (.56, .42, 2), (.6, .72, 2), (.92, .76, 2), (.95, .44, 2)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)]),
  ('Polaris', PlaceKind.star, [0xFFDCD7BA, 0xFFE6C384], 'A Estrela do Norte, quase parada no céu.', [], []),
  ('Cassiopeia', PlaceKind.constellation, [0xFFD27E99], 'A rainha, com o desenho de um W.',
      [(.05, .28, 2), (.3, .72, 2), (.5, .4, 3), (.72, .76, 2), (.95, .24, 2)], [(0, 1), (1, 2), (2, 3), (3, 4)]),
  ('Lira', PlaceKind.constellation, [0xFF7FB4CA], 'A harpa de Orfeu, com a brilhante Vega.',
      [(.3, .12, 3), (.44, .34, 1), (.6, .3, 1), (.7, .78, 2), (.52, .84, 2)], [(0, 1), (0, 2), (1, 2), (1, 4), (2, 3), (3, 4)]),
  ('Vega', PlaceKind.star, [0xFFA3D4D5, 0xFFDCD7BA], 'Daqui a 12 mil anos será a nova estrela polar.', [], []),
  ('Cisne', PlaceKind.constellation, [0xFFDCD7BA], 'Uma cruz no meio da Via Láctea.',
      [(.5, .05, 3), (.5, .4, 2), (.5, .92, 2), (.12, .3, 2), (.88, .52, 2)], [(0, 1), (1, 2), (3, 1), (1, 4)]),
  ('Deneb', PlaceKind.star, [0xFFDCD7BA, 0xFF7FB4CA], 'Uma das estrelas mais luminosas conhecidas, a 2.600 anos-luz.', [], []),
  ('Leão', PlaceKind.constellation, [0xFFE6C384], 'Regulus marca o coração do leão.',
      [(.2, .82, 3), (.22, .56, 2), (.32, .38, 2), (.24, .2, 2), (.36, .1, 1), (.58, .5, 2), (.9, .62, 2), (.62, .78, 2)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5), (5, 6), (6, 7), (7, 0)]),
];

const _syllables = ['Ka', 'Ve', 'Lu', 'Zo', 'Mi', 'Tha', 'Rhe', 'No', 'Ix', 'Se', 'Or', 'Ae', 'Qui', 'Dra'];
const _endings = ['ra', 'on', 'is', 'ae', 'ux', 'ys', 'el', 'ar'];
const _greek = ['Alfa', 'Beta', 'Gama', 'Delta', 'Épsilon', 'Zeta', 'Ômega', 'Sigma'];

int placeHash(int n) {
  var h = n * 2654435761 & 0xFFFFFFFF;
  h ^= h >> 15;
  h = h * 2246822519 & 0xFFFFFFFF;
  h ^= h >> 13;
  return h;
}

/// Missões que cada passo da jornada pede.
int stepCost(Region r) => switch (r) {
      Region.earth => 4,
      Region.solar => 8,
      Region.deep => 12,
    };

final _cache = <int, Place>{};

Place placeAt(int index) => _cache.putIfAbsent(index, () => _build(index));

int _required(int index) {
  var total = 0;
  for (var i = 1; i <= index; i++) {
    final r = i < _cities.length ? Region.earth : (i < _cities.length + _solar.length ? Region.solar : Region.deep);
    total += stepCost(r);
  }
  return total;
}

Place _build(int index) {
  final req = _required(index);
  if (index < _cities.length) {
    final c = _cities[index];
    return Place(index: index, name: c.$1, region: Region.earth, kind: c.$2, colors: c.$3, fact: c.$4, landmark: c.$5, missionsRequired: req);
  }
  var j = index - _cities.length;
  if (j < _solar.length) {
    final c = _solar[j];
    return Place(index: index, name: c.$1, region: Region.solar, kind: c.$2, colors: c.$3, fact: c.$4, missionsRequired: req);
  }
  j -= _solar.length;
  if (j < _deep.length) {
    final c = _deep[j];
    return Place(
        index: index, name: c.$1, region: Region.deep, kind: c.$2, colors: c.$3, fact: c.$4, stars: c.$5, lines: c.$6, missionsRequired: req);
  }
  // Depois das estrelas conhecidas, o espaço profundo é gerado sem fim.
  final h = placeHash(index);
  final word = '${_syllables[h % _syllables.length]}${_syllables[(h >> 5) % _syllables.length].toLowerCase()}'
      '${_endings[(h >> 9) % _endings.length]}';
  final hue = (h % 360).toDouble();
  if (index.isEven) {
    final r = math.Random(h);
    final n = 5 + r.nextInt(4);
    final stars = [for (var i = 0; i < n; i++) (.08 + r.nextDouble() * .84, .08 + r.nextDouble() * .84, 1 + r.nextInt(3))]
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return Place(
      index: index,
      name: 'Constelação $word',
      region: Region.deep,
      kind: PlaceKind.constellation,
      colors: [hslToArgb(hue, .5, .75)],
      fact: 'Constelação ainda sem mapa: você é o primeiro a ligar estas $n estrelas.',
      stars: stars,
      lines: [for (var i = 0; i < n - 1; i++) (i, i + 1)],
      missionsRequired: req,
    );
  }
  return Place(
    index: index,
    name: '${_greek[(h >> 13) % _greek.length]} $word',
    region: Region.deep,
    kind: PlaceKind.star,
    colors: [hslToArgb(hue, .7, .7), hslToArgb((hue + 30) % 360, .6, .55)],
    fact: 'Estrela a ${40 + h % 9000} anos-luz, descoberta pela sua nave.',
    missionsRequired: req,
  );
}

/// Lugar alcançado com [done] missões concluídas.
int placeIndexFor(int done) {
  var i = 0;
  while (placeAt(i + 1).missionsRequired <= done) {
    i++;
  }
  return i;
}

/// Quantos lugares nomeados existem (o resto é gerado).
int get namedPlaces => _cities.length + _solar.length + _deep.length;
