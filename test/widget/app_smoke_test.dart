import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/app/app.dart';
import 'package:rotina_quest/core/time/clock.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/core/weather/weather.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/repositories/game_repository.dart';
import 'package:rotina_quest/features/game/presentation/controllers/game_providers.dart';

class _MemoryRepo implements GameRepository {
  GameState? saved;
  @override
  Future<void> clear() async => saved = null;
  @override
  Future<GameState> load() async => saved ?? GameState.initial('2026-10-21');
  @override
  Future<void> save(GameState state) async => saved = state;
}

Future<_MemoryRepo> _pump(WidgetTester tester, GameState initial) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final repo = _MemoryRepo();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 21, 10))),
      gameRepositoryProvider.overrideWithValue(repo),
      initialGameStateProvider.overrideWithValue(initial),
      weatherSourceProvider.overrideWithValue(() async => const WeatherNow(27, 3)),
    ],
    child: const RotinaQuestApp(),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return repo;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('primeira vez pede o arquivo da agenda', (tester) async {
    await _pump(tester, GameState.initial('2026-10-21'));
    expect(find.text('IMPORTAR AGENDA (.ICS OU .ICAL)'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('marcar missão e abrir as abas', (tester) async {
    final s = GameState.initial(ymd(DateTime(2026, 10, 21)))
      ..name = 'Gui'
      ..onboarded = true
      ..missions.add(Mission(id: 'a', title: 'Academia', days: [2], start: '07:00', end: '08:00', category: 'treino'));
    final repo = await _pump(tester, s);
    expect(find.text('GUI'), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(find.text('Academia')), alignment: .5);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Academia'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.saved!.weeks.values.single.done, hasLength(1));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('1 missão concluída'), findsOneWidget);
    // 1 de 1 missão: a Terra já está explorada nesta semana
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DESTINO EXPLORADO!'), findsOneWidget);
    await tester.tap(find.text('CONTINUAR').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MAPA'), findsNothing);
    expect(find.text('SEMANA'), findsNothing);
    expect(find.text('TAREFAS'), findsNothing);
    for (final tab in ['PERSONAGEM', 'AJUSTES', 'EXPLORAR']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: tab);
      if (tab == 'PERSONAGEM') {
        expect(find.text('ATRIBUTOS'), findsOneWidget);
        // a Disciplina (chama e tarefas) fica na mesma tela
        await tester.scrollUntilVisible(find.text('ADICIONAR'), 300, scrollable: find.byType(Scrollable).first);
        expect(find.text('DISCIPLINA'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Pagar a luz');
        await tester.tap(find.text('ADICIONAR'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Pagar a luz'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(repo.saved!.todos.single.done, isTrue);
        expect(find.text('CONCLUÍDAS HOJE'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      }
    }
    expect(find.text('TERRA'), findsNothing); // a placa é desenhada na cena
    // a semana fica no fim da tela Explorar
    await tester.scrollUntilVisible(find.text('HISTÓRICO'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('ESTA SEMANA'), findsOneWidget);

    // o mapa abre pelo botão em Explorar
    await tester.scrollUntilVisible(find.text('VER MAPA DA JORNADA'), 200, scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.text('VER MAPA DA JORNADA')), alignment: .5);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('VER MAPA DA JORNADA'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('MAPA DA JORNADA'), findsOneWidget);
    expect(find.text('/USR/BIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));

    // tema claro em Ajustes
    await tester.tap(find.text('AJUSTES').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.saved!.light, isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('EXPLORAR').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await _end(tester);
  });
}
