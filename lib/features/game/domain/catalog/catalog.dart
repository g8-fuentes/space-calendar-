import '../../../../core/text/text_utils.dart';

/// Converte HSL (h em graus, s e l de 0 a 1) para ARGB.
int hslToArgb(double h, double s, double l) {
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  final (r, g, b) = switch (h) {
    < 60 => (c, x, 0.0),
    < 120 => (x, c, 0.0),
    < 180 => (0.0, c, x),
    < 240 => (0.0, x, c),
    < 300 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
  return 0xFF000000 | ch(r) << 16 | ch(g) << 8 | ch(b);
}

// ---------- Categorias ----------

/// Categoria da missão: só dá a cor da etiqueta.
class Category {
  const Category(this.key, this.name, this.color);
  final String key;
  final String name;
  final int color;
}

const categories = <Category>[
  Category('cuidado', 'Vitalidade', 0xFFD27E99),
  Category('estudo', 'Mente', 0xFF7FB4CA),
  Category('trabalho', 'Foco', 0xFF7E9CD8),
  Category('treino', 'Força', 0xFFC34043),
  Category('arte', 'Criatividade', 0xFF957FB8),
  Category('espirito', 'Espírito', 0xFFE6C384),
  Category('lazer', 'Diversão', 0xFF98BB6C),
  Category('disciplina', 'Disciplina', 0xFFFFA066),
];

Category categoryOf(String key) => categories.firstWhere((c) => c.key == key, orElse: () => categories.first);

/// Força é só para atividade física. Por isso a regra de Força vem
/// primeiro só com esportes e exercícios de verdade; "treino" sozinho só
/// conta como Força no fim, quando o nome não fala de outra coisa (um
/// "treino de piano" é Criatividade).
final _categoryRules = <(String, RegExp)>[
  (
    'treino',
    RegExp(r'academia|\bgym|muscula|pilates|\byoga|\bioga|corrida|\bcorrer|\brun\b|running|futebol|futsal|futevolei|'
        r'volei|basquete|handebol|natacao|\bnadar|\bbike|bicicleta|ciclismo|\bpedal|crossfit|\bluta\b|\bjiu|boxe|'
        r'muay|\bdanca|caminhada|caminhar|alongamento|workout|esporte|\btenis\b|beach|\bsurf|\bskate|escalada|'
        r'\bremo\b|spinning|funcional|\bhiit|zumba|calistenia|maratona|abdominais|cardio|treino de (perna|braco|'
        r'costas|peito|ombro|gluteo|forca|corrida)|treino fisico|exercicio fisico|atividade fisica|personal')
  ),
  (
    'arte',
    RegExp(r'piano|teclado|violao|violino|guitarra|\bbaixo\b|ukulele|flauta|saxofone|musica|\bcanto\b|bateria|\bfoto|'
        r'desenho|pintura|\barte|escrita|escrever|music|\bdraw|paint|teatro|croche|bordado|coral|instrumento')
  ),
  (
    'estudo',
    RegExp(
        r'aula|estud|curso|leitura|ler |livro|duolingo|idioma|ingles|espanhol|frances|alemao|italiano|japones|english|spanish|study|class|lesson|reading|coddy|program|codigo|faculdade|escola|prova|revis|podcast')
  ),
  (
    'trabalho',
    RegExp(r'trabalho|reuniao|work|meeting|call|expediente|escritorio|cliente|projeto|daily|standup|1:1|freela')
  ),
  ('espirito', RegExp(r'missa|igreja|culto|oracao|orar|meditac|meditar|terco|biblia|retiro|devocional|gratidao')),
  ('lazer', RegExp(r'jogo|game|filme|serie|lazer|passeio|festa|amigos|cinema|descanso|hobby')),
  ('treino', RegExp(r'\btreino|\btreinar|exercicio')),
];

/// Adivinha a categoria pelo nome do evento.
String guessCategory(String title) {
  final n = '${norm(title)} ';
  for (final (k, rx) in _categoryRules) {
    if (rx.hasMatch(n)) return k;
  }
  return 'cuidado';
}

/// Categoria de uma missão já salva. Missões antigas que caíram em Força
/// sem ser atividade física (como "treino de piano") vão para a categoria
/// certa, e os pontos delas também.
String fixCategory(String? saved, String title) {
  final guess = guessCategory(title);
  if (saved == null) return guess;
  return saved == 'treino' && guess != 'treino' ? guess : saved;
}

const dayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const dayAbbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
