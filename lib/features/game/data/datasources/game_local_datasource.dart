import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o estado do jogo como um único JSON no aparelho.
class GameLocalDataSource {
  GameLocalDataSource(this._prefs);

  static const _key = 'rotina_quest.state.v1';
  final SharedPreferences _prefs;

  String? read() => _prefs.getString(_key);

  Future<void> write(String json) => _prefs.setString(_key, json);

  Future<void> delete() => _prefs.remove(_key);
}
