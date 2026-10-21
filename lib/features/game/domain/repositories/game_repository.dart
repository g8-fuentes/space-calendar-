import '../entities/game_state.dart';

/// Contrato de persistência. O domínio não sabe onde o jogo é salvo.
abstract interface class GameRepository {
  Future<GameState> load();
  Future<void> save(GameState state);
  Future<void> clear();
}
