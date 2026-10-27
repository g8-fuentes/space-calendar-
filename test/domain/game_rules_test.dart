import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/core/sound/music.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/core/weather/weather.dart';
import 'package:rotina_quest/features/game/domain/catalog/passages.dart';
import 'package:rotina_quest/features/game/domain/catalog/places.dart';
import 'package:rotina_quest/features/game/domain/catalog/transformations.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/services/calendar_import.dart';
import 'package:rotina_quest/features/game/domain/services/game_rules.dart';
import 'package:rotina_quest/features/game/domain/services/game_stats.dart';
import 'package:rotina_quest/features/game/presentation/controllers/game_providers.dart';
import 'package:rotina_quest/features/game/presentation/widgets/explore_scene.dart';

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
      expect((missions.first.start, missions.first.end), ('07:00', '08:00'));
      expect(r.info.skippedAllDay, 1);
    });

    test('recusa o que não é .ics ou .cal', () {
      expect(parseCalendar('rotina.csv', 'titulo,dia\nLer,seg', now).error, isNotNull);
    });

    test('importar de novo mantém o que já foi marcado', () {
      final s = GameState.initial(ymd(now));
      GameRules.importMissions(s, [
        Mission(id: 'a', title: 'Ler', days: [2], start: '20:00', end: '21:00')
      ]);
      GameRules.toggle(s, s.missions.single, 2, now);
      GameRules.importMissions(s, [
        Mission(id: 'novo', title: 'Ler', days: [2, 4], start: '20:00', end: '21:00'),
        Mission(id: 'b', title: 'Correr', days: [1], start: '06:00', end: '07:00'),
      ]);
      final ler = s.missions.firstWhere((m) => m.title == 'Ler');
      expect(ler.id, 'a');
      expect(ler.days, [2, 4]);
      expect(s.weeks[weekKeyOf(now)]!.done.containsKey(slotKey(ler, 2)), isTrue);
    });
  });

  group('exploração', () {
    test('começa em Belém e passa pela Terra Santa, o caminho ao céu e os céus', () {
      expect(placeAt(0).name, 'Belém');
      expect(placeAt(0).region, Region.land);
      final firstAscent = List.generate(80, placeAt).firstWhere((p) => p.region == Region.ascent);
      expect(firstAscent.name, 'Acima das nuvens');
      expect(placeAt(namedPlaces - 1).region, Region.heaven);
      expect(placeAt(0).closeness, 0);
      expect(placeAt(namedPlaces - 1).closeness, 1);
      // depois dos nomeados, os céus continuam sem fim
      expect(placeAt(namedPlaces).name, 'Moradas do Pai');
      expect(placeAt(namedPlaces + 7).name, 'Moradas do Pai II');
      expect(placeAt(namedPlaces + 5).region, Region.heaven);
      for (var i = 1; i < namedPlaces + 10; i++) {
        expect(placeAt(i).missionsRequired, greaterThan(placeAt(i - 1).missionsRequired));
      }
    });

    test('marcar missões avança o lugar e avisa', () {
      final s = GameState.initial(ymd(now))..lastPlace = 0;
      final m = Mission(id: 'a', title: 'Estudar', days: [0, 1, 2, 3, 4, 5, 6], start: '08:00', end: '09:00');
      s.missions.add(m);
      for (var d = 0; d < 4; d++) {
        expect(GameRules.toggle(s, m, d, now), isTrue);
      }
      final t = computeStats(s, now);
      expect(t.missionsDone, 4);
      expect(t.place.name, 'Nazaré');
      final notices = GameRules.progressNotices(s, t);
      expect(notices.single.text, contains('Nazaré'));
      expect(GameRules.toggle(s, m, 0, now), isFalse);
      expect(computeStats(s, now).missionsDone, 3);
    });

    test('estado sobrevive a JSON', () {
      final s = GameState.initial(ymd(now))..name = 'Gui';
      s.missions.add(Mission(id: 'a', title: 'Ler', days: [1], start: '20:00', end: '21:00'));
      GameRules.toggle(s, s.missions.single, 1, now);
      final back = s.copy();
      expect(back.name, 'Gui');
      expect(back.missions.single.title, 'Ler');
      expect(computeStats(back, now).missionsDone, 1);
    });
  });

  group('personagem', () {
    test('missões dão pontos ao atributo da categoria pela duração', () {
      expect(pointsFor(null), 3);
      expect(pointsFor(60), 6);
      expect(pointsFor(5), 3);
      expect(pointsFor(600), 24);
      final s = GameState.initial(ymd(now));
      s.missions
          .add(Mission(id: 'a', title: 'Academia', days: [0, 1, 2], start: '07:00', end: '08:30', category: 'treino'));
      for (final d in [0, 1, 2]) {
        GameRules.toggle(s, s.missions.single, d, now);
      }
      final t = computeStats(s, now);
      expect(t.attributes['treino'], 27);
      expect(t.power, 27);
      expect(t.best!.name, 'Força');
      expect(t.form.title, 'Nível 1 · Buscador');
      expect(t.powerMissing, 13);
      // só aparecem os atributos das missões
      expect(t.shown.map((c) => c.name), ['Força']);
      s.missions.add(Mission(id: 'b', title: 'Ler', days: [3], start: '20:00', end: '21:00', category: 'estudo'));
      expect(computeStats(s, now).shown.map((c) => c.name), ['Mente', 'Força']);
    });

    test('cada nível traz uma passagem da Bíblia, sem nível final', () {
      expect(transformationIndexFor(0), 0);
      expect(transformationIndexFor(39), 0);
      expect(transformationIndexFor(40), 1);
      expect(transformationIndexFor(95), 2);
      expect(transformationAt(0).passage.ref, 'Gênesis 1:1');
      expect(passages.map((p) => p.ref).toSet(), hasLength(passages.length));
      for (var i = 1; i < passages.length * 2 + 5; i++) {
        final f = transformationAt(i);
        expect(f.power, greaterThan(transformationAt(i - 1).power));
        expect(f.power - transformationAt(i - 1).power, lessThanOrEqualTo(400));
        expect(f.passage.text, isNotEmpty);
        expect(f.aura, greaterThanOrEqualTo(transformationAt(i - 1).aura));
      }
      // depois da última passagem a lista recomeça, mas os níveis continuam
      final after = transformationAt(passages.length);
      expect(after.passage.ref, passages.first.ref);
      expect(after.level, passages.length + 1);
      final far = transformationAt(500);
      expect((far.halo, far.rays, far.wings), (2, true, true));
      expect(transformationIndexFor(far.power), 500);
    });

    test('avisa cada nova bênção com a passagem', () {
      final s = GameState.initial(ymd(now))
        ..lastForm = 0
        ..lastPlace = 0;
      final m = Mission(
          id: 'a', title: 'Estudar', days: [0, 1, 2, 3, 4, 5, 6], start: '08:00', end: '12:00', category: 'estudo');
      s.missions.add(m);
      for (final d in [0, 1]) {
        GameRules.toggle(s, m, d, now);
      }
      var notices = GameRules.progressNotices(s, computeStats(s, now));
      expect(notices.map((n) => n.title), ['NOVA BÊNÇÃO!']);
      expect(notices.single.form, 1);
      expect(notices.single.text, contains(transformationAt(1).passage.ref));
      // muitas missões depois, sai da Terra
      var space = 0;
      while (placeAt(space).region == Region.land) {
        space++;
      }
      final earthEnd = placeAt(space).missionsRequired;
      for (var w = 0; w < earthEnd; w++) {
        s.weeks['2020-W${w.toString().padLeft(3, '0')}'] = WeekRecord()
          ..done['a@0'] = const DoneRecord(day: 0, title: 'Estudar', at: 0, category: 'estudo', minutes: 240);
      }
      final t = computeStats(s, now);
      expect(t.place.region, isNot(Region.land));
      notices = GameRules.progressNotices(s, t);
      expect(notices.map((n) => n.title), ['NOVA BÊNÇÃO!', 'RUMO AO CÉU!']);
    });
  });

  test('um aviso por dia de cada missão com horário', () {
    final s = GameState.initial('2026-10-21')
      ..missions.addAll([
        Mission(id: 'a', title: 'Academia', days: [0, 2], start: '07:00', end: '08:00'),
        Mission(id: 'b', title: 'Ler', days: [1]),
      ]);
    final list = alertsFor(s);
    expect(list.map((a) => (a.day, a.minutes)), [(0, 420), (2, 420)]);
    expect(list.first.title, contains('Academia'));
    s.alerts = false;
    expect(alertsFor(s), isEmpty);
  });

  test('sol das 6h às 18h, lua no resto', () {
    expect(isSunUp(12), isTrue);
    expect(isSunUp(5.9), isFalse);
    expect(isSunUp(18.5), isFalse);
    expect(dayLight(23), 0);
    expect(dayLight(12), 1);
  });

  test('códigos do Open-Meteo viram tipos de tempo', () {
    expect(skyOfCode(0), Sky.clear);
    expect(skyOfCode(3), Sky.cloudy);
    expect(skyOfCode(63), Sky.rain);
    expect(skyOfCode(95), Sky.storm);
    expect(labelOfCode(2), 'parcialmente nublado');
  });

  test('cada música é gerada sem estourar o volume', () {
    for (final s in songs) {
      final samples = renderSong(s);
      expect(samples.length, greaterThan(22050 * 20), reason: s.title);
      expect(samples.every((v) => v.isFinite && v.abs() <= 1), isTrue, reason: s.title);
    }
  });
}
