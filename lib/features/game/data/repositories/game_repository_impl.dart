import 'dart:convert';

import '../../../../core/time/clock.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_local_datasource.dart';

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl(this._local, this._clock);

  final GameLocalDataSource _local;
  final Clock _clock;

  @override
  Future<GameState> load() async {
    final today = ymd(_clock.now());
    final raw = _local.read();
    if (raw == null) return GameState.initial(today);
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      final state = GameState.fromJson(decoded, today: today);
      // Itens que saíram da loja não ficam equipados.
      state.owned.removeWhere((id) => !isCosmetic(id));
      state.equipped.removeWhere((_, id) => !isCosmetic(id));
      return state;
    } on FormatException {
      return GameState.initial(today);
    } on TypeError {
      // Dados antigos ou corrompidos: começa de novo em vez de travar.
      return GameState.initial(today);
    }
  }

  @override
  Future<void> save(GameState state) => _local.write(jsonEncode(state.toJson()));

  @override
  Future<void> clear() => _local.delete();
}
