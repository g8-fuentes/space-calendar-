import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/features/game/domain/catalog/catalog.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/services/calendar_import.dart';
import 'package:rotina_quest/features/game/domain/services/game_rules.dart';
import 'package:rotina_quest/features/game/domain/services/game_stats.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10); // quarta-feira

  group('importação', () {
    test('lê eventos semanais de um .ics', () {
      const ics = 'BEGIN:VCALENDAR\r\n'
          'BEGIN:VEVENT\r\nSUMMARY:Academia\r\nDTSTART:20261019T070000\r\nDTEND:20261019T080000\r\n'
          'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR\r\nEND:VEVENT\r\n'
          'BEGIN:VEVENT\r\nSUMMARY:Feriado\r\nDTSTART;VALUE=DATE:20261020\r\nEND:VEVENT\r\n'
          'END:VCALENDAR\r\n';
      final r = parseCalendar('agenda.ics', ics, now);
      expect(r.error, isNull);
      final missions = toMissions(r.events);
      expect(missions, hasLength(1));
      expect(missions.first.title, 'Academia');
      expect(missions.first.days, [0, 2, 4]);
      expect(missions.first.start, '07:00');
      expect(missions.first.end, '08:00');
      expect(r.info.skippedAllDay, 1);
    });

    test('lê .csv com cabeçalho em português e junta dias iguais', () {
      const csv = 'titulo,dia,inicio,fim\nInglês,seg,19:00,20:00\nInglês,qua,19:00,20:00\nLeitura,dom,21:00,\n';
      final missions = toMissions(parseCalendar('rotina.csv', csv, now).events);
      expect(missions, hasLength(2));
      final ingles = missions.firstWhere((m) => m.title == 'Inglês');
      expect(ingles.days, [0, 2]);
      final leitura = missions.firstWhere((m) => m.title == 'Leitura');
      expect(leitura.end, '22:00');
    });

    test('arquivo .ics inválido devolve erro', () {
      expect(parseCalendar('x.ics', 'nada aqui', now).error, isNotNull);
    });
  });

  group('Google Agenda', () {
    const ics = 'BEGIN:VCALENDAR\n'
        'BEGIN:VEVENT\nSUMMARY:Academia\nDTSTART:20261019T070000\nDTEND:20261019T080000\nRRULE:FREQ=WEEKLY;BYDAY=MO,WE\nEND:VEVENT\n'
        'BEGIN:VEVENT\nSUMMARY:Dentista\nDTSTART:20261023T150000\nDTEND:20261023T160000\nEND:VEVENT\n'
        'BEGIN:VEVENT\nSUMMARY:Viagem\nDTSTART:20261110T090000\nDTEND:20261110T100000\nEND:VEVENT\n'
        'END:VCALENDAR\n';

    test('sincronização só traz eventos avulsos desta semana', () {
      final titles = toMissions(parseIcs(ics, now, thisWeekOnly: true).events).map((m) => m.title).toSet();
      expect(titles, {'Academia', 'Dentista'});
    });

    test('ressincronizar mantém o que foi marcado e não mexe em missões manuais', () {
      final s = GameState.initial(ymd(now));
      s.missions.add(Mission(id: 'eu', title: 'Ler', days: [2], start: '21:00', end: '22:00'));
      GameRules.syncCalendar(s, toMissions(parseIcs(ics, now, thisWeekOnly: true).events));
      final academia = s.missions.firstWhere((m) => m.title == 'Academia');
      GameRules.toggle(s, academia, 2, now);

      final later = DateTime(2026, 11, 10, 8);
      final (total, added, removed) = GameRules.syncCalendar(s, toMissions(parseIcs(ics, later, thisWeekOnly: true).events));
      expect((total, added, removed), (2, 1, 1));
      expect(s.missions.firstWhere((m) => m.title == 'Academia').id, academia.id);
      expect(s.missions.any((m) => m.title == 'Dentista'), isFalse);
      expect(s.missions.firstWhere((m) => m.title == 'Viagem').synced, isTrue);
      expect(s.missions.firstWhere((m) => m.id == 'eu').synced, isFalse);
      expect(s.copy().missions.where((m) => m.synced), hasLength(2));
    });

    test('aceita webcal:// e recusa texto qualquer', () {
      expect(normalizeCalendarUrl(' webcal://calendar.google.com/x/basic.ics '), 'https://calendar.google.com/x/basic.ics');
      expect(normalizeCalendarUrl('minha agenda'), isNull);
    });
  });

  group('regras', () {
    test('XP da missão depende da categoria e da duração', () {
      final m = Mission(id: 'a', title: 'Treino', days: [0], start: '07:00', end: '08:00', category: 'treino');
      expect(questXp(m), 40);
      m.end = '09:30';
      expect(questXp(m), 100);
    });

    test('marcar e desmarcar missão muda XP e moedas', () {
      final s = GameState.initial(ymd(now));
      final m = Mission(id: 'a', title: 'Estudar', days: [2], start: '08:00', end: '09:00', category: 'estudo');
      s.missions.add(m);
      expect(GameRules.toggle(s, m, 2, now), isNotNull);
      final t = computeStats(s, now);
      expect(t.xp, 30);
      expect(t.coins, 6);
      expect(GameRules.toggle(s, m, 2, now), isNull);
      expect(computeStats(s, now).xp, 0);
    });

    test('semana completa libera o baú de ouro', () {
      final s = GameState.initial(ymd(now));
      final m = Mission(id: 'a', title: 'Ler', days: [0, 1], start: '20:00', end: '21:00', category: 'estudo');
      s.missions.add(m);
      final k = weekKeyOf(now);
      expect(GameRules.openChest(s, k, now), isNull);
      GameRules.toggle(s, m, 0, now);
      GameRules.toggle(s, m, 1, now);
      final chest = GameRules.openChest(s, k, now);
      expect(chest?.tier, 'ouro');
      expect(GameRules.openChest(s, k, now), isNull);
    });

    test('cada nível tem um inimigo e o 10 é chefe', () {
      expect(enemyFor(3).name, isNot(enemyFor(4).name));
      expect(enemyFor(10).boss, isTrue);
      expect(enemyFor(9).boss, isFalse);
    });

    test('estado sobrevive a JSON', () {
      final s = GameState.initial(ymd(now))..name = 'Gui';
      s.missions.add(Mission(id: 'a', title: 'Ler', days: [1], start: '20:00', end: '21:00'));
      final back = s.copy();
      expect(back.name, 'Gui');
      expect(back.missions.single.title, 'Ler');
    });
  });
}
