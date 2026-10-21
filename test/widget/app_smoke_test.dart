import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/app/app.dart';
import 'package:rotina_quest/app/theme/kanagawa.dart';
import 'package:rotina_quest/core/time/clock.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/repositories/game_repository.dart';
import 'package:rotina_quest/features/game/presentation/controllers/game_providers.dart';

class _MemoryRepository implements GameRepository {
  GameState? saved;
  @override
  Future<void> clear() async => saved = null;
  @override
  Future<GameState> load() async => saved!;
  @override
  Future<void> save(GameState state) async => saved = state;
}

void main() {
  setUpAll(() => PixelText.useGoogleFonts = false);

  testWidgets('abre o app e marca uma missão', (tester) async {
    final now = DateTime(2026, 10, 21, 9);
    final repo = _MemoryRepository();
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(now)),
        gameRepositoryProvider.overrideWithValue(repo),
        initialGameStateProvider.overrideWithValue(GameState.initial(ymd(now))),
      ],
      child: const RotinaQuestApp(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('GUILHERME FUENTES'), findsOneWidget);
    expect(find.text('Leitura'), findsOneWidget);

    await tester.tap(find.text('Leitura'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.saved?.week(weekKeyOf(now)).done, isNotEmpty);
  });
}
