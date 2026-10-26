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
int _weekday(DateTime d) => d.weekday - 1;
String _hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// Lê uma agenda .ics/.cal (iCalendar) e devolve os eventos semanais.
ImportResult parseCalendar(String fileName, String text, DateTime now) {
  if (!RegExp('BEGIN:VCALENDAR|BEGIN:VEVENT', caseSensitive: false).hasMatch(text)) {
    return ImportResult([], ImportInfo(), 'Esse arquivo não é uma agenda .ics ou .cal. Exporte a agenda no Google Agenda e escolha o arquivo .ics.');
  }
  return parseIcs(text, now);
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

