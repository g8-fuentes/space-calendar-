import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/services/state_merge.dart';

GameState _phone() => GameState.initial('2026-10-01')
  ..name = 'Gui'
  ..onboarded = true
  ..missions.add(Mission(id: 'p1', title: 'Academia', days: [0, 2], start: '07:00', end: '08:00'))
  ..week('2026-10-19').done['p1@0'] = const DoneRecord(day: 0, title: 'Academia', at: 100)
  ..explored.add('2026-10-12')
  ..todos.add(Todo(id: 't1', text: 'Ler', doneAt: 50));

GameState _pc() => GameState.initial('2026-10-10')
  ..name = 'Guilherme'
  ..onboarded = true
  ..light = true
  ..missions.add(Mission(id: 'c1', title: 'Academia', days: [2], start: '07:00', end: '08:00'))
  ..missions.add(Mission(id: 'c2', title: 'Inglês', days: [1], start: '19:00', end: '20:00'))
  ..week('2026-10-19').done['c1@2'] = const DoneRecord(day: 2, title: 'Academia', at: 200)
  ..week('2026-10-19').skipped.add(4)
  ..todos.add(Todo(id: 't1', text: 'Ler'))
  ..todos.add(Todo(id: 't2', text: 'Commit'));

void main() {
  test('juntar celular e computador não perde nada', () {
    final m = mergeStates(_pc(), _phone());
    // opções vêm do save mais novo
    expect(m.name, 'Guilherme');
    expect(m.light, isTrue);
    // missão igual vira uma só, com os dias dos dois
    expect(m.missions.map((x) => x.id), ['c1', 'c2']);
    expect(m.missions.first.days, [0, 2]);
    // conclusões dos dois, a do celular remapeada para o id do computador
    expect(m.weeks['2026-10-19']!.done.keys.toSet(), {'c1@0', 'c1@2'});
    expect(m.weeks['2026-10-19']!.skipped, {4});
    expect(m.explored, {'2026-10-12'});
    // tarefa concluída em um aparelho fica concluída
    expect(m.todos.firstWhere((t) => t.id == 't1').doneAt, 50);
    expect(m.todos.length, 2);
    expect(m.startDate, '2026-10-01');
  });

  test('aparelho novo é reconhecido como vazio', () {
    expect(isPristine(GameState.initial('2026-10-01')), isTrue);
    expect(isPristine(_phone()), isFalse);
  });
}
