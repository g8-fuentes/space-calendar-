import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/time/clock.dart';
import 'features/game/data/datasources/game_local_datasource.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/presentation/controllers/game_providers.dart';

/// Composição da aplicação: cria as dependências concretas e injeta
/// no Riverpod. Nenhuma tela conhece SharedPreferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const clock = SystemClock();
  final prefs = await SharedPreferences.getInstance();
  final repository = GameRepositoryImpl(GameLocalDataSource(prefs), clock);
  final initial = await repository.load();

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
}
