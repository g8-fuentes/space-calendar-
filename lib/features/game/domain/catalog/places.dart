import 'catalog.dart' show hslToArgb;

/// As três fases da exploração: o Sistema Solar, as estrelas vizinhas
/// (exoplanetas) e a galáxia e além.
enum Region { solar, stars, galaxy }

/// Como o lugar é desenhado.
enum PlaceKind { home, earth, moon, rocky, gas, ring, belt, star, nebula, blackHole, galaxy }

/// Monumento desenhado no horizonte de uma cidade.
enum Landmark {
  none,
  christ,
  cityTower,
  needle,
  ironTower,
  clockTower,
  coliseum,
  pyramids,
  onionDome,
  pagoda,
  dome,
  opera,
  obelisk
}

String regionName(Region r) => switch (r) {
      Region.solar => 'Sistema Solar',
      Region.stars => 'Estrelas vizinhas',
      Region.galaxy => 'Galáxia e além',
    };

/// Um destino da exploração. Cada semana o dev explora um destino.
class Place {
  const Place({
    required this.index,
    required this.name,
    required this.region,
    required this.kind,
    required this.colors,
    required this.fact,
    this.landmark = Landmark.none,
  });

  final int index;
  final String name;
  final Region region;
  final PlaceKind kind;
  final List<int> colors;
  final String fact;
  final Landmark landmark;

  /// Semana da jornada em que o dev explora este lugar (1 = a primeira).
  int get week => index + 1;
}

typedef _P = (String, PlaceKind, List<int>, String);

const _solar = <_P>[
  ('Terra', PlaceKind.home, [0xFF7E9CD8, 0xFF98BB6C], 'Base de lançamento em Bauru. Daqui o dev parte para o espaço.'),
  ('Lua', PlaceKind.moon, [0xFF938AA9, 0xFF727169], 'Fica a 384 mil km. A luz dela leva 1,3 segundo para chegar aqui.'),
  ('Mercúrio', PlaceKind.moon, [0xFF727169, 0xFF54546D], 'O mais perto do Sol: um ano lá dura só 88 dias.'),
  (
    'Vênus',
    PlaceKind.rocky,
    [0xFFE6C384, 0xFFC0A36E],
    'O planeta mais quente: 465 °C, mesmo sem ser o mais perto do Sol.'
  ),
  (
    'Marte',
    PlaceKind.rocky,
    [0xFFFFA066, 0xFFC34043],
    'Tem o Monte Olimpo, vulcão três vezes mais alto que o Everest.'
  ),
  (
    'Cinturão de asteroides',
    PlaceKind.belt,
    [0xFF938AA9, 0xFFC0A36E],
    'Entre Marte e Júpiter. O maior corpo dele é Ceres, um planeta anão.'
  ),
  ('Júpiter', PlaceKind.gas, [0xFFFFA066, 0xFFE6C384, 0xFFC0A36E], 'Caberiam 1.300 Terras dentro dele.'),
  (
    'Europa',
    PlaceKind.moon,
    [0xFFDCD7BA, 0xFFC0A36E],
    'Lua de Júpiter que esconde um oceano de água salgada sob o gelo.'
  ),
  ('Saturno', PlaceKind.ring, [0xFFE6C384, 0xFFC8C093], 'É tão leve que boiaria numa banheira gigante.'),
  ('Titã', PlaceKind.rocky, [0xFFFFA066, 0xFFE6C384], 'Lua de Saturno com rios e lagos, só que de metano.'),
  ('Urano', PlaceKind.gas, [0xFFA3D4D5, 0xFF7FB4CA], 'Gira deitado, quase de lado em relação ao Sol.'),
  ('Netuno', PlaceKind.gas, [0xFF7E9CD8, 0xFF223249], 'Tem os ventos mais rápidos do Sistema Solar: até 2.100 km/h.'),
  ('Plutão', PlaceKind.moon, [0xFFC0A36E, 0xFFDCD7BA], 'Planeta anão com um coração de gelo de nitrogênio.'),
  (
    'Nuvem de Oort',
    PlaceKind.belt,
    [0xFFA3D4D5, 0xFFDCD7BA],
    'A borda do Sistema Solar: bilhões de blocos de gelo a mais de um ano-luz.'
  ),
];

const _stars = <_P>[
  (
    'Proxima Centauri b',
    PlaceKind.rocky,
    [0xFFC34043, 0xFF727169],
    'O exoplaneta mais perto: 4,2 anos-luz, na zona onde poderia haver água.'
  ),
  (
    'TRAPPIST-1e',
    PlaceKind.earth,
    [0xFF2D4F67, 0xFF98BB6C],
    'Um dos sete planetas do tamanho da Terra em volta de uma estrela anã vermelha.'
  ),
  ('Kepler-16b', PlaceKind.gas, [0xFFC0A36E, 0xFF938AA9], 'Gira em volta de dois sóis, como Tatooine em Star Wars.'),
  ('55 Cancri e', PlaceKind.rocky, [0xFFFF5D62, 0xFFFFA066], 'Um mundo de lava onde um ano dura só 18 horas.'),
  (
    'HD 189733 b',
    PlaceKind.gas,
    [0xFF7E9CD8, 0xFF7FB4CA],
    'Planeta azul onde chove vidro de lado, com ventos de 7 mil km/h.'
  ),
  ('Kepler-452b', PlaceKind.earth, [0xFF7E9CD8, 0xFF98BB6C], 'O "primo da Terra": um ano lá dura 385 dias.'),
  ('Sirius', PlaceKind.star, [0xFFA3D4D5, 0xFFDCD7BA], 'A estrela mais brilhante do céu noturno, a 8,6 anos-luz.'),
  (
    'Betelgeuse',
    PlaceKind.star,
    [0xFFFF5D62, 0xFFFFA066],
    'Supergigante vermelha: se estivesse no lugar do Sol, engoliria Marte.'
  ),
];

const _galaxy = <_P>[
  (
    'Nebulosa de Órion',
    PlaceKind.nebula,
    [0xFFD27E99, 0xFF7FB4CA, 0xFF957FB8],
    'Um berçário de estrelas a 1.300 anos-luz, visível a olho nu.'
  ),
  (
    'Pilares da Criação',
    PlaceKind.nebula,
    [0xFFFFA066, 0xFF98BB6C, 0xFF7E9CD8],
    'Colunas de gás onde nascem estrelas, na Nebulosa da Águia.'
  ),
  (
    'Sagitário A*',
    PlaceKind.blackHole,
    [0xFFFFA066, 0xFFE6C384],
    'O buraco negro no centro da Via Láctea, com 4 milhões de vezes a massa do Sol.'
  ),
  (
    'Grande Nuvem de Magalhães',
    PlaceKind.galaxy,
    [0xFFA3D4D5, 0xFFD27E99],
    'Galáxia vizinha a 160 mil anos-luz, vista a olho nu do hemisfério sul.'
  ),
  (
    'Andrômeda',
    PlaceKind.galaxy,
    [0xFFDCD7BA, 0xFF957FB8],
    'A 2,5 milhões de anos-luz. Um dia pode se juntar à Via Láctea.'
  ),
];

const _syllables = ['Ka', 'Ve', 'Lu', 'Zo', 'Mi', 'Tha', 'Rhe', 'No', 'Ix', 'Se', 'Or', 'Ae', 'Qui', 'Dra'];
const _endings = ['ra', 'on', 'is', 'ae', 'ux', 'ys', 'el', 'ar'];
const _newKinds = [PlaceKind.rocky, PlaceKind.gas, PlaceKind.earth, PlaceKind.ring, PlaceKind.moon, PlaceKind.nebula];

int placeHash(int n) {
  var h = n * 2654435761 & 0xFFFFFFFF;
  h ^= h >> 15;
  h = h * 2246822519 & 0xFFFFFFFF;
  h ^= h >> 13;
  return h;
}

final _cache = <int, Place>{};

/// Destino da semana [index] da jornada (0 = a primeira semana, na Terra).
Place placeAt(int index) => _cache.putIfAbsent(index, () => _build(index));

Place _build(int index) {
  var j = index;
  for (final (list, region) in [(_solar, Region.solar), (_stars, Region.stars), (_galaxy, Region.galaxy)]) {
    if (j < list.length) {
      final (name, kind, colors, fact) = list[j];
      return Place(
        index: index,
        name: name,
        region: region,
        kind: kind,
        colors: colors,
        fact: fact,
        landmark: kind == PlaceKind.home ? Landmark.obelisk : Landmark.none,
      );
    }
    j -= list.length;
  }
  // Depois dos lugares conhecidos, a galáxia é gerada sem fim.
  final h = placeHash(index);
  final word = '${_syllables[h % _syllables.length]}${_syllables[(h >> 5) % _syllables.length].toLowerCase()}'
      '${_endings[(h >> 9) % _endings.length]}';
  final hue = (h % 360).toDouble();
  final kind = _newKinds[(h >> 11) % _newKinds.length];
  final colors = [hslToArgb(hue, .55, .62), hslToArgb((hue + 40) % 360, .5, .45), hslToArgb((hue + 80) % 360, .5, .7)];
  if (kind == PlaceKind.nebula) {
    return Place(
      index: index,
      name: 'Nebulosa $word',
      region: Region.galaxy,
      kind: kind,
      colors: colors,
      fact: 'Nuvem de gás a ${1000 + h % 90000} anos-luz, ainda sem mapa. Você é o primeiro a ver.',
    );
  }
  return Place(
    index: index,
    name: '$word-${10 + (h >> 4) % 990} b',
    region: Region.galaxy,
    kind: kind,
    colors: colors,
    fact: 'Exoplaneta a ${40 + h % 9000} anos-luz, descoberto pela sua nave.',
  );
}

/// Quantos lugares nomeados existem (o resto é gerado).
int get namedPlaces => _solar.length + _stars.length + _galaxy.length;
