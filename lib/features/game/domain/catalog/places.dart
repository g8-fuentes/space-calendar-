import '../../../../core/text/text_utils.dart';
import 'catalog.dart' show hslToArgb;

/// O que aparece atrás do dev em cada destino.
enum PlaceKind { laptop, server, cloud, network, mainframe, core, matrix }

const regions = ['Máquina local', 'A rede', 'Dentro da Matrix'];

/// Um destino da jornada pelo terminal. Cada semana o dev entra num
/// destino novo.
class Place {
  const Place({
    required this.index,
    required this.name,
    required this.stage,
    required this.kind,
    required this.color,
    required this.fact,
  });

  final int index;
  final String name;

  /// Fase da jornada (0, 1 ou 2), ver [regions].
  final int stage;
  final PlaceKind kind;

  /// Cor de destaque do lugar.
  final int color;
  final String fact;

  String get region => regions[stage];

  /// Semana da jornada em que o dev entra neste lugar (1 = a primeira).
  int get week => index + 1;

  /// Caminho mostrado no prompt do terminal.
  String get path {
    if (name.startsWith('~') || name.startsWith('/') || name.startsWith('.')) return name;
    return '/${norm(name).replaceAll(RegExp(r'[^a-z0-9.]+'), '-')}';
  }
}

typedef _P = (String, PlaceKind, String);

const _stages = <List<_P>>[
  [
    ('~', PlaceKind.laptop, 'O til (~) é o atalho para a sua pasta pessoal no terminal. Tudo começa aqui.'),
    ('/usr/bin', PlaceKind.laptop, 'Onde moram programas do sistema como ls, cat e grep.'),
    ('/etc', PlaceKind.laptop, 'A pasta dos arquivos de configuração do sistema.'),
    ('localhost', PlaceKind.server, '127.0.0.1: o endereço que sempre aponta para a sua própria máquina.'),
    ('.git', PlaceKind.server, 'O Git foi criado por Linus Torvalds em 2005.'),
    ('/dev/null', PlaceKind.core, 'O buraco negro do Unix: tudo o que vai para lá desaparece.'),
  ],
  [
    ('Porta 22', PlaceKind.network, 'A porta do SSH, o jeito seguro de entrar em outros servidores.'),
    ('github.com', PlaceKind.cloud, 'Onde mais de 100 milhões de desenvolvedores guardam código.'),
    ('Servidor de produção', PlaceKind.server, 'Onde o código encontra os usuários. Nunca faça deploy na sexta.'),
    ('Data center', PlaceKind.server, 'Milhares de servidores ligados dia e noite, com muito ar-condicionado.'),
    ('Cabo submarino', PlaceKind.network, 'Quase todo o tráfego entre continentes passa por cabos no fundo do mar.'),
    ('A nuvem', PlaceKind.cloud, 'A nuvem é só o computador de outra pessoa.'),
    ('Rede neural', PlaceKind.network, 'Camadas de neurônios artificiais aprendendo com dados.'),
  ],
  [
    ('Mainframe', PlaceKind.mainframe, 'Mainframes ainda processam boa parte das transações bancárias do mundo.'),
    ('Kernel', PlaceKind.core, 'O coração do sistema operacional: fala direto com o hardware.'),
    ('Chuva de código', PlaceKind.matrix, 'Na tela verde, cada coluna que cai é um fluxo de dados.'),
    ('Código-fonte da Matrix', PlaceKind.matrix, 'Aqui o código e a realidade são a mesma coisa.'),
    ('Além da simulação', PlaceKind.core, 'Você enxerga o código por trás de tudo.'),
  ],
];

const _kindColors = {
  PlaceKind.laptop: 0xFF3CFF6B,
  PlaceKind.server: 0xFF7FB4CA,
  PlaceKind.cloud: 0xFFA3D4D5,
  PlaceKind.network: 0xFF957FB8,
  PlaceKind.mainframe: 0xFFE6C384,
  PlaceKind.core: 0xFFFF5D62,
  PlaceKind.matrix: 0xFF3CFF6B,
};

int placeHash(int n) {
  var h = n * 2654435761 & 0xFFFFFFFF;
  h ^= h >> 15;
  h = h * 2246822519 & 0xFFFFFFFF;
  h ^= h >> 13;
  return h;
}

final _cache = <int, Place>{};

/// Destino da semana [index] da jornada (0 = a primeira semana, em ~).
Place placeAt(int index) => _cache.putIfAbsent(index, () {
      var j = index;
      for (var st = 0; st < _stages.length; st++) {
        if (j < _stages[st].length) {
          final (name, kind, fact) = _stages[st][j];
          return Place(index: index, name: name, stage: st, kind: kind, color: _kindColors[kind]!, fact: fact);
        }
        j -= _stages[st].length;
      }
      // Depois dos lugares conhecidos, a Matrix é gerada sem fim.
      final h = placeHash(index);
      final kind = PlaceKind.values[h % PlaceKind.values.length];
      return Place(
        index: index,
        name: 'nó ${(h & 0xFFFF).toRadixString(16).padLeft(4, '0')}.matrix',
        stage: 2,
        kind: kind,
        color: hslToArgb((h >> 8) % 360 * 1.0, .7, .62),
        fact: 'Um nó novo da Matrix, ainda sem mapa. A jornada não tem fim.',
      );
    });

/// Quantos lugares nomeados existem (o resto é gerado).
int get namedPlaces => _stages.fold(0, (a, s) => a + s.length);
