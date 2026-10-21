import '../../../../core/text/text_utils.dart';
import '../catalog/catalog.dart';
import '../entities/game_state.dart';

/// Evento lido de um arquivo, antes de virar missão.
class ImportedEvent {
  ImportedEvent(this.title, this.days, this.start, this.end, [this.category]);
  final String title;
  final List<int> days;
  final String start;
  final String end;
  final String? category;
}

class ImportInfo {
  int total = 0;
  int skippedAllDay = 0;
  int skippedOld = 0;
  int skippedOther = 0;
}

class ImportResult {
  ImportResult(this.events, this.info, [this.error]);
  final List<ImportedEvent> events;
  final ImportInfo info;
  final String? error;
}

const _icsDays = {'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6};
const _dayMap = {
  'seg': 0, 'mon': 0, 'ter': 1, 'tue': 1, 'qua': 2, 'wed': 2, 'qui': 3, 'thu': 3,
  'sex': 4, 'fri': 4, 'sab': 5, 'sat': 5, 'dom': 6, 'sun': 6,
};

int _weekday(DateTime d) => d.weekday - 1;
String _hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// Lê .ics/.cal (iCalendar) ou .csv e devolve os eventos semanais.
ImportResult parseCalendar(String fileName, String text, DateTime now) {
  if (RegExp('BEGIN:VCALENDAR|BEGIN:VEVENT', caseSensitive: false).hasMatch(text)) {
    return parseIcs(text, now);
  }
  if (RegExp(r'\.(ics|cal|ical|vcs)$', caseSensitive: false).hasMatch(fileName)) {
    return ImportResult([], ImportInfo(), 'Esse arquivo não parece um calendário .ics válido.');
  }
  return parseCsv(text);
}

({bool allDay, DateTime date})? _icsDate(String v) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?').firstMatch(v.trim());
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  if (m[4] == null) return (allDay: true, date: DateTime(y, mo, d));
  final h = int.parse(m[4]!), mi = int.parse(m[5]!);
  final date = m[7] != null ? DateTime.utc(y, mo, d, h, mi).toLocal() : DateTime(y, mo, d, h, mi);
  return (allDay: false, date: date);
}

String _unescape(String s) =>
    s.replaceAll(RegExp(r'\\n', caseSensitive: false), ' ').replaceAllMapped(RegExp(r'\\([,;\\])'), (m) => m[1]!).trim();

/// [thisWeekOnly]: eventos avulsos só entram se caírem na semana de [now]
/// (usado na sincronização, que roda toda semana).
ImportResult parseIcs(String text, DateTime now, {bool thisWeekOnly = false}) {
  final lines = text.replaceAll(RegExp(r'\r\n?'), '\n').replaceAll(RegExp(r'\n[ \t]'), '').split('\n');
  final events = <Map<String, (String, String)>>[];
  Map<String, (String, String)>? cur;
  for (final ln in lines) {
    final u = ln.trim().toUpperCase();
    if (u == 'BEGIN:VEVENT') {
      cur = {};
      continue;
    }
    if (u == 'END:VEVENT') {
      if (cur != null) events.add(cur);
      cur = null;
      continue;
    }
    if (cur == null) continue;
    final i = ln.indexOf(':');
    if (i < 0) continue;
    final head = ln.substring(0, i).split(';');
    cur[head.first.toUpperCase()] = (ln.substring(i + 1), head.skip(1).join(';'));
  }

  final info = ImportInfo()..total = events.length;
  final out = <ImportedEvent>[];
  final today = now;
  final monday = DateTime(now.year, now.month, now.day - _weekday(now));
  final from = thisWeekOnly ? monday : DateTime(now.year, now.month, now.day - 35);
  final to = thisWeekOnly ? monday.add(const Duration(days: 7)) : DateTime(now.year, now.month, now.day + 63);
  final once = <(ImportedEvent, DateTime)>[];

  for (final e in events) {
    final summary = e['SUMMARY'], dtstart = e['DTSTART'];
    if (summary == null || dtstart == null) {
      info.skippedOther++;
      continue;
    }
    if (e.containsKey('RECURRENCE-ID')) continue;
    if (e['STATUS'] != null && RegExp('CANCEL', caseSensitive: false).hasMatch(e['STATUS']!.$1)) {
      info.skippedOther++;
      continue;
    }
    final st = _icsDate(dtstart.$1);
    if (st == null) {
      info.skippedOther++;
      continue;
    }
    if (st.allDay) {
      info.skippedAllDay++;
      continue;
    }
    DateTime? en = e['DTEND'] == null ? null : _icsDate(e['DTEND']!.$1)?.date;
    if (en == null && e['DURATION'] != null) {
      final dm = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(e['DURATION']!.$1);
      if (dm != null) {
        en = st.date.add(Duration(hours: int.tryParse(dm[1] ?? '') ?? 0, minutes: int.tryParse(dm[2] ?? '') ?? 0));
      }
    }
    if (en != null && en.difference(st.date).inHours > 24) {
      info.skippedOther++;
      continue;
    }
    final title = _unescape(summary.$1).isEmpty ? 'Missão' : _unescape(summary.$1);
    final s = _hm(st.date), endStr = _hm(en ?? st.date.add(const Duration(hours: 1)));
    final wd = _weekday(st.date);
    final rrule = e['RRULE'];
    if (rrule != null) {
      final r = <String, String>{};
      for (final kv in rrule.$1.split(';')) {
        final p = kv.split('=');
        r[p.first.toUpperCase()] = p.length > 1 ? p[1] : '';
      }
      if (r['UNTIL'] != null) {
        final u = _icsDate(r['UNTIL']!);
        if (u != null && u.date.isBefore(today)) {
          info.skippedOld++;
          continue;
        }
      }
      if (r['COUNT'] != null) {
        final by = r['BYDAY'] != null ? r['BYDAY']!.split(',').length : 1;
        final iv = int.tryParse(r['INTERVAL'] ?? '') ?? 1;
        final per = r['FREQ'] == 'DAILY' ? 1 : 7 / by;
        final count = int.tryParse(r['COUNT']!) ?? 0;
        final end = st.date.add(Duration(minutes: (count * iv * per * 1440).round()));
        if (end.isBefore(today)) {
          info.skippedOld++;
          continue;
        }
      }
      List<int> days;
      if (r['FREQ'] == 'WEEKLY' || r['FREQ'] == 'DAILY') {
        if (r['BYDAY'] != null && r['BYDAY']!.isNotEmpty) {
          days = [
            for (final x in r['BYDAY']!.split(','))
              if (_icsDays[_lastTwo(x.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase())] case final d?) d,
          ];
        } else {
          days = r['FREQ'] == 'DAILY' ? [0, 1, 2, 3, 4, 5, 6] : [wd];
        }
      } else {
        info.skippedOther++;
        continue;
      }
      out.add(ImportedEvent(title, days, s, endStr));
    } else {
      once.add((ImportedEvent(title, [wd], s, endStr), st.date));
    }
  }
  var selected = once.where((o) => !o.$2.isBefore(from) && (thisWeekOnly ? o.$2.isBefore(to) : !o.$2.isAfter(to))).toList();
  if (!thisWeekOnly && out.isEmpty && selected.isEmpty) selected = once;
  info.skippedOld += once.length - selected.length;
  out.addAll(selected.map((o) => o.$1));
  return ImportResult(out, info);
}

String _lastTwo(String s) => s.length <= 2 ? s : s.substring(s.length - 2);

List<List<String>> splitCsv(String text) {
  final first = text.split(RegExp(r'\r?\n')).first;
  int count(String ch) => first.split(ch).length;
  final delim = ([',', ';', '\t']..sort((a, b) => count(b).compareTo(count(a)))).first;
  final rows = <List<String>>[];
  var row = <String>[];
  final f = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          f.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        f.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == delim) {
      row.add(f.toString());
      f.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(f.toString());
      rows.add(row);
      row = [];
      f.clear();
    } else {
      f.write(c);
    }
  }
  if (f.isNotEmpty || row.isNotEmpty) {
    row.add(f.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((x) => x.trim().isNotEmpty)).toList();
}

String parseTime(String v) {
  final s = norm(v).replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return '';
  final m = RegExp(r'^(\d{1,2})(?:[:h.](\d{2}))?h?(am|pm)?$').firstMatch(s) ?? RegExp(r'^(\d{2})(\d{2})$').firstMatch(s);
  if (m == null) return '';
  var h = int.parse(m[1]!);
  final mi = int.tryParse(m.groupCount >= 2 ? m[2] ?? '0' : '0') ?? 0;
  final ampm = m.groupCount >= 3 ? m[3] : null;
  if (ampm == 'pm' && h < 12) h += 12;
  if (ampm == 'am' && h == 12) h = 0;
  if (h > 23 || mi > 59) return '';
  return '${two(h)}:${two(mi)}';
}

List<int> parseDays(String v) {
  final n = norm(v);
  if (n.isEmpty) return [];
  if (RegExp('todos|diari|daily|every|toda').hasMatch(n)) return [0, 1, 2, 3, 4, 5, 6];
  if (RegExp(r'uteis|weekday|seg.*sex').hasMatch(n) && !RegExp(r'[,/|]').hasMatch(n)) return [0, 1, 2, 3, 4];
  if (RegExp('fim de semana|weekend').hasMatch(n)) return [5, 6];
  final out = <int>[];
  for (final p in n.split(RegExp(r'[/,|;+]| e | and |\s+'))) {
    final letters = p.replaceAll(RegExp('[^a-z]'), '');
    final k = letters.length > 3 ? letters.substring(0, 3) : letters;
    final d = _dayMap[k];
    if (d != null && !out.contains(d)) out.add(d);
  }
  return out..sort();
}

DateTime? parseDate(String v) {
  final s = v.trim();
  var m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (m != null) return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  m = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})').firstMatch(s);
  if (m != null) {
    final a = int.parse(m[1]!), b = int.parse(m[2]!);
    var y = int.parse(m[3]!);
    if (y < 100) y += 2000;
    int d, mo;
    if (a > 12) {
      d = a;
      mo = b;
    } else if (b > 12) {
      mo = a;
      d = b;
    } else {
      d = a;
      mo = b;
    }
    return DateTime(y, mo, d);
  }
  return DateTime.tryParse(s);
}

ImportResult parseCsv(String text) {
  final rows = splitCsv(text);
  final info = ImportInfo();
  if (rows.isEmpty) return ImportResult([], info);
  final head = rows.first.map(norm).toList();
  int find(String re) => head.indexWhere((h) => RegExp(re).hasMatch(h));
  var ti = find(r'^(subject|title|titulo|summary|nome|evento|missao|atividade|name|event|assunto|tarefa)');
  var di = find(r'^(dia|day|weekday|dias|days|dia da semana)$');
  final dt = find(r'(start date|^data|^date|data inicio|data de inicio|startdate)');
  var si = find(r'(start time|^inicio|hora inicio|hora de inicio|^start$|^hora$|^horario|^de$)');
  var ei = find(r'(end time|^fim|hora fim|hora de fim|termino|^end$|^ate$)');
  final ci = find(r'^(categoria|category)$');
  final ad = find('all day|dia inteiro|dia todo');
  var body = rows.skip(1).toList();
  if (ti < 0 && di < 0 && dt < 0) {
    ti = 0;
    di = 1;
    si = 2;
    ei = 3;
    body = rows;
  }
  if (ti < 0) ti = 0;
  String at(List<String> r, int i) => i >= 0 && i < r.length ? r[i] : '';
  final out = <ImportedEvent>[];
  for (final r in body) {
    info.total++;
    final t = at(r, ti).trim();
    if (t.isEmpty) {
      info.skippedOther++;
      continue;
    }
    if (ad >= 0 && RegExp('true|sim|yes|1', caseSensitive: false).hasMatch(at(r, ad))) {
      info.skippedAllDay++;
      continue;
    }
    var days = di >= 0 ? parseDays(at(r, di)) : <int>[];
    if (days.isEmpty && dt >= 0) {
      final d = parseDate(at(r, dt));
      if (d != null) days = [_weekday(d)];
    }
    if (days.isEmpty) {
      info.skippedOther++;
      continue;
    }
    final s = si >= 0 ? parseTime(at(r, si)) : '';
    var e = ei >= 0 ? parseTime(at(r, ei)) : '';
    if (s.isNotEmpty && e.isEmpty) e = hhmmOf(minutesOf(s)! + 60);
    String? cat;
    if (ci >= 0) {
      final v = norm(at(r, ci));
      for (final c in categories) {
        if (norm(c.name) == v || c.key == v) cat = c.key;
      }
    }
    out.add(ImportedEvent(t, days, s, s.isNotEmpty ? e : '', cat));
  }
  return ImportResult(out, info);
}

/// Junta eventos iguais (mesmo nome e horário) numa missão de vários dias.
List<Mission> toMissions(List<ImportedEvent> list) {
  final map = <String, Mission>{};
  for (final x in list) {
    final k = '${norm(x.title)}|${x.start}|${x.end}';
    final m = map[k];
    if (m != null) {
      for (final d in x.days) {
        if (!m.days.contains(d)) m.days.add(d);
      }
    } else {
      map[k] = Mission(
        id: uid(),
        title: x.title.length > 80 ? x.title.substring(0, 80) : x.title,
        days: List.of(x.days),
        start: x.start,
        end: x.end,
        category: x.category ?? guessCategory(x.title),
      );
    }
  }
  final arr = map.values.take(300).toList();
  for (final m in arr) {
    m.days.sort();
  }
  return arr;
}

/// Agenda de exemplo para quem quer só experimentar.
(List<Mission>, List<Course>) demoSchedule() {
  ImportedEvent l(String t, List<int> d, String s, String e, String c) => ImportedEvent(t, d, s, e, c);
  final ms = toMissions([
    l('Banho e café', [0, 1, 2, 3, 4], '06:30', '07:00', 'cuidado'),
    l('Leitura', [0, 1, 2, 3, 4, 5, 6], '07:00', '07:30', 'estudo'),
    l('Trabalho', [0, 1, 2, 3, 4], '08:00', '12:00', 'trabalho'),
    l('Academia', [0, 2, 4], '12:00', '13:00', 'treino'),
    l('Almoço', [0, 1, 2, 3, 4, 5, 6], '13:00', '13:30', 'cuidado'),
    l('Trabalho', [0, 1, 2, 3, 4], '14:00', '18:00', 'trabalho'),
    l('Aula de inglês', [1, 3], '19:00', '20:00', 'estudo'),
    l('Curso online', [0, 2], '19:00', '20:00', 'estudo'),
    l('Violão', [4], '19:00', '20:00', 'arte'),
    l('Duolingo', [0, 1, 2, 3, 4, 5, 6], '21:00', '21:30', 'estudo'),
    l('Futebol com amigos', [5], '10:00', '12:00', 'treino'),
    l('Faxina da semana', [5], '14:00', '15:30', 'cuidado'),
    l('Meditação', [6], '18:00', '18:30', 'espirito'),
  ]);
  final en = Course(id: uid(), name: 'Inglês', kind: 'lang', color: 0xFF7FB4CA);
  final dev = Course(id: uid(), name: 'Curso de programação', kind: 'course', color: 0xFF957FB8, total: 40);
  final gui = Course(id: uid(), name: 'Violão para iniciantes', kind: 'course', color: 0xFFE6C384);
  for (final m in ms) {
    if (RegExp('ingles|duolingo').hasMatch(norm(m.title))) m.link = en.id;
    if (m.title == 'Curso online') m.link = dev.id;
    if (m.title == 'Violão') m.link = gui.id;
  }
  return (ms, [dev, gui, en]);
}

/// Aceita o endereço iCal colado (https:// ou webcal://). null = inválido.
String? normalizeCalendarUrl(String raw) {
  var u = raw.trim();
  if (u.isEmpty) return null;
  if (u.toLowerCase().startsWith('webcal://')) u = 'https://${u.substring(9)}';
  final uri = Uri.tryParse(u);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) return null;
  return u;
}
