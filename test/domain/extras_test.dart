import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/core/sound/music.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/presentation/controllers/game_providers.dart';
import 'package:rotina_quest/features/game/presentation/widgets/space_scene.dart';

void main() {
  test('cada música é gerada sem estourar o volume', () {
    for (final s in songs) {
      final samples = renderSong(s);
      expect(samples.length, greaterThan(22050 * 20), reason: s.title);
      expect(samples.every((v) => v.isFinite && v.abs() <= 1), isTrue, reason: s.title);
    }
  });

  test('um aviso por dia de cada missão com horário', () {
    final s = GameState.initial('2026-10-21')
      ..missions.addAll([
        Mission(id: 'a', title: 'Academia', days: [0, 2], start: '07:00', end: '08:00', category: 'treino'),
        Mission(id: 'b', title: 'Ler', days: [1]),
      ]);
    final list = alertsFor(s);
    expect(list.map((a) => (a.day, a.minutes)), [(0, 420), (2, 420)]);
    expect(list.first.title, contains('Academia'));
    expect(list.first.id, isNot(list.last.id));
    s.alerts = false;
    expect(alertsFor(s), isEmpty);
  });

  test('sol de dia, lua e estrelas à noite', () {
    final noon = skyAt(12), night = skyAt(23), dusk = skyAt(18);
    expect(noon.day, 1);
    expect(noon.sun, isNotNull);
    expect(noon.moon, isNull);
    expect(night.day, 0);
    expect(night.moon, isNotNull);
    expect(night.sun, isNull);
    expect(dusk.dusk, greaterThan(.9));
  });
}
