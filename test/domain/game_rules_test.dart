import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/core/sound/music.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/core/weather/weather.dart';
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
    test('um destino por semana: Terra, planetas, estrelas e galáxia, sem fim', () {
      expect(placeAt(0).name, 'Terra');
      expect(placeAt(0).kind, PlaceKind.home);
      expect(placeAt(1).name, 'Lua');
      expect(placeAt(4).name, 'Marte');
      final firstStar = List.generate(80, placeAt).firstWhere((p) => p.region == Region.stars);
      expect(firstStar.name, 'Proxima Centauri b');
      expect(placeAt(firstStar.index - 1).name, 'Nuvem de Oort');
      expect(placeAt(namedPlaces - 1).name, 'Andrômeda');
      // depois dos nomeados, continua gerando
      final extra = placeAt(namedPlaces + 5);
      expect(extra.region, Region.galaxy);
      expect(extra.name, isNotEmpty);
      expect(placeAt(namedPlaces + 5).week, namedPlaces + 6);
    });

    test('metade das missões da semana explora o destino; o próximo vem na segunda', () {
      final s = GameState.initial(ymd(now))..lastPlace = 0;
      final m = Mission(id: 'a', title: 'Estudar', days: [0, 1, 2, 3, 4, 5, 6], start: '08:00', end: '09:00');
      s.missions.add(m);
      expect(s.weeklyGoal, 4);
      for (var d = 0; d < 3; d++) {
        GameRules.toggle(s, m, d, now);
      }
      var t = computeStats(s, now);
      expect((t.place.name, t.weekDone, t.missing, t.explored), ('Terra', 3, 1, false));
      expect(GameRules.progressNotices(s, t), isEmpty);
      GameRules.toggle(s, m, 3, now);
      t = computeStats(s, now);
      expect(t.explored, isTrue);
      expect(t.place.name, 'Terra');
      final notices = GameRules.progressNotices(s, t);
      expect(notices.single.title, 'DESTINO EXPLORADO!');
      expect(notices.single.text, contains('Lua'));
      expect(s.explored, {weekKeyOf(now)});
      // na semana seguinte, a nave chega à Lua
      final monday = DateTime(2026, 10, 26, 9);
      t = computeStats(s, monday);
      expect((t.place.name, t.weekDone), ('Lua', 0));
      expect(GameRules.progressNotices(s, t).single.text, contains('Semana 2: Lua.'));
      // desmarcar na mesma semana tira a exploração
      GameRules.toggle(s, m, 0, now);
      GameRules.progressNotices(s, computeStats(s, now));
      expect(s.explored, isEmpty);
    });

    test('sair do Sistema Solar avisa', () {
      final s = GameState.initial(ymd(now));
      final solar = List.generate(80, placeAt).where((p) => p.region == Region.solar).length;
      for (var w = 0; w < solar - 1; w++) {
        s.explored.add(ymd(DateTime(2025, 1, 6 + 7 * w)));
      }
      s.lastPlace = computeStats(s, now).placeIndex;
      s.explored.add(ymd(DateTime(2026, 10, 12)));
      final t = computeStats(s, now);
      expect(t.place.region, Region.stars);
      expect(GameRules.progressNotices(s, t).map((n) => n.title), ['ALÉM DO SISTEMA SOLAR!']);
    });

    test('saves antigos contam as semanas que já cumpriam a meta', () {
      final s = GameState.initial(ymd(now))
        ..missions.add(Mission(id: 'a', title: 'Ler', days: [0, 1], start: '20:00', end: '21:00'));
      s.weeks['2026-10-12'] = WeekRecord()..done['a@0'] = const DoneRecord(day: 0, title: 'Ler', at: 0);
      s.weeks['2026-10-05'] = WeekRecord();
      final json = s.toJson()..remove('explored');
      final back = GameState.fromJson(json, today: ymd(now));
      expect(back.explored, {'2026-10-12'});
      expect(computeStats(back, now).place.name, 'Lua');
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
      expect(t.form.title, 'Nível 1 · Estagiário');
      expect(t.form.quote.author, 'Linus Torvalds');
      expect(t.powerMissing, 13);
      // só aparecem os atributos das missões
      expect(t.shown.map((c) => c.name), ['Força']);
      s.missions.add(Mission(id: 'b', title: 'Ler', days: [3], start: '20:00', end: '21:00', category: 'estudo'));
      expect(computeStats(s, now).shown.map((c) => c.name), ['Mente', 'Força']);
    });

    test('pontos liberam os níveis de dev, sem fim', () {
      expect(transformationIndexFor(0), 0);
      expect(transformationIndexFor(39), 0);
      expect(transformationIndexFor(40), 1);
      expect(transformationAt(transformationIndexFor(550)).name, 'Staff Engineer');
      expect(transformationIndexFor(7200), namedTransformations - 1);
      expect(transformationAt(namedTransformations).name, 'Dev Cósmico 2');
      expect(transformationIndexFor(8700), namedTransformations);
      expect(
          Hair.values
              .every((h) => [for (var i = 0; i < namedTransformations; i++) transformationAt(i).hair].contains(h)),
          isTrue);
      for (var i = 1; i < namedTransformations + 3; i++) {
        expect(transformationAt(i).power, greaterThan(transformationAt(i - 1).power));
      }
    });

    test('avisa o nível novo', () {
      final s = GameState.initial(ymd(now))
        ..lastForm = 0
        ..lastPlace = 0;
      final m = Mission(
          id: 'a', title: 'Estudar', days: [0, 1, 2, 3, 4, 5, 6], start: '08:00', end: '12:00', category: 'estudo');
      s.missions.add(m);
      for (final d in [0, 1]) {
        GameRules.toggle(s, m, d, now);
      }
      final notices = GameRules.progressNotices(s, computeStats(s, now));
      expect(notices.map((n) => n.title), ['NOVO NÍVEL!']);
      expect(notices.single.text, startsWith('Nível 2 · Dev Júnior'));
      expect(notices.single.form, 1);
    });
  });

  test('eventos do Google Agenda viram missões da semana', () {
    final items = <Map<String, Object?>>[
      for (final d in ['2026-10-19', '2026-10-21'])
        {
          'summary': 'Academia',
          'start': {'dateTime': '${d}T07:00:00-03:00'},
          'end': {'dateTime': '${d}T08:00:00-03:00'},
        },
      {
        'summary': 'Feriado',
        'start': {'date': '2026-10-20'},
        'end': {'date': '2026-10-21'},
      },
      {
        'summary': 'Reunião recusada',
        'start': {'dateTime': '2026-10-20T10:00:00-03:00'},
        'end': {'dateTime': '2026-10-20T11:00:00-03:00'},
        'attendees': [
          {'self': true, 'responseStatus': 'declined'}
        ],
      },
      {
        'status': 'cancelled',
        'summary': 'Cancelado',
        'start': {'dateTime': '2026-10-22T10:00:00-03:00'},
      },
    ];
    final events = eventsFromGoogle(items);
    expect(events, hasLength(2));
    final missions = toMissions(events);
    expect(missions.single.title, 'Academia');
    expect(missions.single.days, [0, 2]);
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
