import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/startup_error.dart';
import 'core/time/clock.dart';
import 'core/time/week_utils.dart';
import 'features/game/data/datasources/game_local_datasource.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/domain/entities/game_state.dart';
import 'features/game/presentation/controllers/game_providers.dart';

/// Composição da aplicação: cria as dependências concretas e injeta
/// no Riverpod. Nenhuma tela conhece SharedPreferences.
///
/// Se algo falhar na abertura, o app mostra o erro na tela em vez de
/// ficar parado na tela de carregamento.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => StartupErrorBox(message: details.exceptionAsString());

  try {
    unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));

    const clock = SystemClock();
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
    final repository = GameRepositoryImpl(GameLocalDataSource(prefs), clock);
    GameState initial;
    try {
      initial = await repository.load();
    } catch (_) {
      // Progresso ilegível: começa do zero em vez de travar.
      initial = GameState.initial(ymd(clock.now()));
    }

    runApp(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(clock),
          gameRepositoryProvider.overrideWithValue(repository),
          initialGameStateProvider.overrideWithValue(initial),
        ],
        child: const RotinaQuestApp(),
      ),
    );
  } catch (error, stack) {
    runApp(StartupErrorApp(error: error, stack: stack));
  }
}
