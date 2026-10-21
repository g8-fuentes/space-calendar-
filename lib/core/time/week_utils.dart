String _two(int n) => n.toString().padLeft(2, '0');

/// Data no formato aaaa-mm-dd.
String ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Segunda-feira (00:00) da semana de [d].
DateTime mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

/// Chave da semana: a data da segunda-feira.
String weekKeyOf(DateTime d) => ymd(mondayOf(d));

/// Índice do dia na semana: 0 = segunda ... 6 = domingo.
int dayIndexOf(DateTime d) => d.weekday - 1;

/// Data do dia [dayIndex] da semana [weekKey].
DateTime dateOf(String weekKey, int dayIndex) {
  final m = DateTime.parse(weekKey);
  return DateTime(m.year, m.month, m.day + dayIndex);
}

int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

String hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
