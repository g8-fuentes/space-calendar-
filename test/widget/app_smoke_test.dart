import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/app/app.dart';
import 'package:rotina_quest/core/time/clock.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
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

void main() {
  testWidgets('tela inicial leva ao jogo e as abas abrem', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 21, 10);
    final repo = _MemoryRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(now)),
        gameRepositoryProvider.overrideWithValue(repo),
        initialGameStateProvider.overrideWithValue(GameState.initial(ymd(now))),
      ],
      child: const RotinaQuestApp(),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, 'Gui');
    await tester.tap(find.text('COMEÇAR SEM CALENDÁRIO'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('BEM-VINDO, GUI'), findsOneWidget);
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.saved?.onboarded, isTrue);
    expect(find.text('GUI'), findsWidgets);

    for (final tab in ['CURSOS', 'LOJA', 'SEMANA', 'MAIS', 'CONQUISTAS', 'AJUSTES', 'MISSÕES']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: tab);
    }

    await Scrollable.ensureVisible(tester.element(find.text('CONECTAR GOOGLE AGENDA')), alignment: .5);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('CONECTAR GOOGLE AGENDA'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Endereço secreto iCal'), findsOneWidget);
    await tester.tap(find.text('CONECTAR'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('https://'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
