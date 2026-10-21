import 'dart:math' as math;

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
};

/// Minúsculas, sem acentos e sem espaços nas pontas: para comparar textos.
String norm(String? s) {
  final lower = (s ?? '').toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_accents[ch] ?? ch);
  }
  return b.toString().trim();
}

String two(int n) => n.toString().padLeft(2, '0');

final _rand = math.Random();

/// Identificador curto e único o bastante para missões e cursos.
String uid() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) + _rand.nextInt(1 << 30).toRadixString(36);

/// "07:30" -> 450. Vazio ou inválido -> null.
int? minutesOf(String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return null;
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]);
  if (h == null) return null;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return h * 60 + m;
}

String hhmmOf(int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  return '${two(m ~/ 60)}:${two(m % 60)}';
}

String roman(int n) {
  const v = [
    (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
    (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
  ];
  final b = StringBuffer();
  for (final (a, s) in v) {
    while (n >= a) {
      b.write(s);
      n -= a;
    }
  }
  return b.toString();
}
