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
];

Category categoryOf(String key) =>
    categories.firstWhere((c) => c.key == key, orElse: () => categories.first);

final _categoryRules = <(String, RegExp)>[
  ('treino', RegExp(r'academia|treino|gym|muscul|pilates|yoga|ioga|corrida|correr|run|futebol|futsal|futevolei|volei|basquete|natacao|nadar|bike|ciclismo|crossfit|luta|jiu|boxe|muay|danca|caminhada|alongamento|workout|esporte|tenis|beach')),
  ('estudo', RegExp(r'aula|estud|curso|leitura|ler |livro|duolingo|idioma|ingles|espanhol|frances|alemao|italiano|japones|english|spanish|study|class|lesson|reading|coddy|program|codigo|faculdade|escola|prova|revis|podcast')),
  ('trabalho', RegExp(r'trabalho|reuniao|work|meeting|call|expediente|escritorio|cliente|projeto|daily|standup|1:1|freela')),
  ('arte', RegExp(r'piano|violao|guitarra|musica|canto|bateria|foto|desenho|pintura|arte|escrita|escrever|music|draw|paint|teatro|croche|bordado')),
  ('espirito', RegExp(r'missa|igreja|culto|oracao|orar|meditac|meditar|terco|biblia|retiro|devocional|gratidao')),
  ('lazer', RegExp(r'jogo|game|filme|serie|lazer|passeio|festa|amigos|cinema|descanso|hobby')),
];

/// Adivinha a categoria pelo nome do evento.
String guessCategory(String title) {
  final n = '${norm(title)} ';
  for (final (k, rx) in _categoryRules) {
    if (rx.hasMatch(n)) return k;
  }
  return 'cuidado';
}

const dayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const dayAbbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
