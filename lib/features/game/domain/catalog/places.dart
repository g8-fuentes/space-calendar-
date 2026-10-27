/// As três fases da jornada: a Terra Santa, o caminho ao céu e os céus.
enum Region { land, ascent, heaven }

/// Como o lugar é desenhado na cena.
enum Scene {
  // Terra Santa
  manger,
  village,
  river,
  sea,
  mount,
  jars,
  city,
  garden,
  crosses,
  tomb,
  road,
  ascension,
  flames,
  // caminho ao céu
  clouds,
  ladder,
  rainbow,
  dove,
  pillar,
  // céus
  gates,
  street,
  lifeRiver,
  tree,
  throne,
}

String regionName(Region r) => switch (r) {
      Region.land => 'Terra Santa',
      Region.ascent => 'Caminho ao Céu',
      Region.heaven => 'Céus',
    };

class Place {
  const Place({
    required this.index,
    required this.name,
    required this.region,
    required this.scene,
    required this.fact,
    required this.missionsRequired,
  });

  final int index;
  final String name;
  final Region region;
  final Scene scene;
  final String fact;

  /// Missões concluídas (no total) para chegar aqui.
  final int missionsRequired;

  /// Quão perto de Jesus (0 a 1): cresce a cada passo da jornada.
  double get closeness => (index / (namedPlaces - 1)).clamp(0.0, 1.0);
}

typedef _P = (String, Scene, String);

const _land = <_P>[
  ('Belém', Scene.manger, 'Jesus nasceu em Belém e foi deitado numa manjedoura (Lucas 2).'),
  ('Nazaré', Scene.village, 'Na pequena Nazaré, Jesus cresceu em sabedoria e em graça (Lucas 2:52).'),
  ('Rio Jordão', Scene.river, 'No Jordão, Jesus foi batizado e o Espírito desceu como pomba (Mateus 3).'),
  ('Mar da Galileia', Scene.sea, 'Aqui Jesus chamou pescadores: "Vinde após mim" (Mateus 4:19).'),
  ('Monte das Bem-aventuranças', Scene.mount, 'Onde Jesus ensinou o Sermão do Monte (Mateus 5).'),
  ('Caná', Scene.jars, 'Numa festa de casamento, a água virou vinho: o primeiro sinal (João 2).'),
  ('Jerusalém', Scene.city, 'A cidade santa, onde Jesus entrou aclamado com ramos (João 12).'),
  ('Getsêmani', Scene.garden, 'No jardim das oliveiras, Jesus orou: "Seja feita a tua vontade" (Mateus 26).'),
  ('Gólgota', Scene.crosses, 'Na cruz, Jesus deu a vida por amor (João 19).'),
  ('Túmulo vazio', Scene.tomb, '"Ele não está aqui, porque já ressuscitou" (Mateus 28:6).'),
  ('Caminho de Emaús', Scene.road, 'Jesus caminhou com dois discípulos, e o coração deles ardia (Lucas 24).'),
  ('Monte das Oliveiras', Scene.ascension, 'Daqui Jesus subiu aos céus, e uma nuvem o recebeu (Atos 1:9).'),
  ('Cenáculo', Scene.flames, 'No Pentecostes, línguas de fogo e o Espírito Santo (Atos 2).'),
];

const _ascent = <_P>[
  ('Acima das nuvens', Scene.clouds, '"Os céus manifestam a glória de Deus" (Salmos 19:1).'),
  ('Escada de Jacó', Scene.ladder, 'Jacó sonhou com uma escada que ia da terra ao céu (Gênesis 28).'),
  ('Arco da aliança', Scene.rainbow, 'O arco-íris é o sinal da aliança de Deus (Gênesis 9:13).'),
  ('Pomba da paz', Scene.dove, 'A pomba voltou com um ramo de oliveira: era paz (Gênesis 8:11).'),
  ('Coluna de luz', Scene.pillar, 'Deus guiava o seu povo com uma coluna de fogo à noite (Êxodo 13:21).'),
];

const _heaven = <_P>[
  ('Portões de pérola', Scene.gates, 'Cada porta da cidade santa é uma só pérola (Apocalipse 21:21).'),
  ('Ruas de ouro', Scene.street, 'A praça da cidade é de ouro puro, como vidro transparente (Apocalipse 21:21).'),
  ('Rio da vida', Scene.lifeRiver, 'Um rio puro, claro como cristal, sai do trono de Deus (Apocalipse 22:1).'),
  ('Árvore da vida', Scene.tree, 'Dá frutos todo mês, e suas folhas curam as nações (Apocalipse 22:2).'),
  ('Diante do trono', Scene.throne, 'Ao redor do trono há um arco-íris como esmeralda (Apocalipse 4:3).'),
];

/// Depois dos lugares nomeados, os céus seguem sem fim.
const _endless = <_P>[
  ('Moradas do Pai', Scene.gates, '"Na casa de meu Pai há muitas moradas" (João 14:2).'),
  (
    'Mar de cristal',
    Scene.lifeRiver,
    'Diante do trono há como que um mar de vidro, semelhante ao cristal (Apocalipse 4:6).'
  ),
  ('Jardim celeste', Scene.tree, 'Não haverá mais dor, porque as primeiras coisas passaram (Apocalipse 21:4).'),
  ('Cidade de luz', Scene.street, 'A cidade não precisa de sol, porque a glória de Deus a ilumina (Apocalipse 21:23).'),
  ('Coro dos anjos', Scene.throne, '"Santo, Santo, Santo é o Senhor" (Isaías 6:3).'),
  ('Fonte de água viva', Scene.lifeRiver, '"Quem tem sede, venha" (Apocalipse 22:17).'),
  ('Monte Sião', Scene.gates, 'O monte da cidade do Deus vivo, a Jerusalém celestial (Hebreus 12:22).'),
];

const _roman = ['', ' II', ' III', ' IV', ' V', ' VI', ' VII', ' VIII', ' IX', ' X'];

/// Missões que cada passo da jornada pede.
int stepCost(Region r) => switch (r) {
      Region.land => 4,
      Region.ascent => 8,
      Region.heaven => 12,
    };

Region _regionOf(int i) => i < _land.length
    ? Region.land
    : i < _land.length + _ascent.length
        ? Region.ascent
        : Region.heaven;

final _cache = <int, Place>{};
final _required = <int>[0];

int _requiredAt(int index) {
  while (_required.length <= index) {
    _required.add(_required.last + stepCost(_regionOf(_required.length)));
  }
  return _required[index];
}

Place placeAt(int index) => _cache.putIfAbsent(index, () {
      final req = _requiredAt(index);
      var j = index;
      for (final (list, region) in [(_land, Region.land), (_ascent, Region.ascent), (_heaven, Region.heaven)]) {
        if (j < list.length) {
          final (name, scene, fact) = list[j];
          return Place(index: index, name: name, region: region, scene: scene, fact: fact, missionsRequired: req);
        }
        j -= list.length;
      }
      final (name, scene, fact) = _endless[j % _endless.length];
      final round = j ~/ _endless.length + 1;
      return Place(
        index: index,
        name: '$name${round <= _roman.length ? _roman[round - 1] : ' $round'}',
        region: Region.heaven,
        scene: scene,
        fact: fact,
        missionsRequired: req,
      );
    });

/// Lugar alcançado com [done] missões concluídas.
int placeIndexFor(int done) {
  var i = 0;
  while (placeAt(i + 1).missionsRequired <= done) {
    i++;
  }
  return i;
}

/// Quantos lugares nomeados existem (o resto é gerado).
int get namedPlaces => _land.length + _ascent.length + _heaven.length;
