import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/sync/cloud_client.dart';

/// O que o aparelho lembra sobre a sincronização: a sessão de login, a
/// versão da nuvem que ele já tem ([base]) e se há mudanças locais ainda
/// não enviadas ([dirty]).
abstract interface class SyncStore {
  CloudSession? get session;
  set session(CloudSession? s);
  String? get base;
  set base(String? v);
  bool get dirty;
  set dirty(bool v);
}

class MemorySyncStore implements SyncStore {
  @override
  CloudSession? session;
  @override
  String? base;
  @override
  bool dirty = false;
}

class PrefsSyncStore implements SyncStore {
  PrefsSyncStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kSession = 'rotina_quest.sync.session',
      _kBase = 'rotina_quest.sync.base',
      _kDirty = 'rotina_quest.sync.dirty';

  @override
  CloudSession? get session {
    final raw = _prefs.getString(_kSession);
    if (raw == null) return null;
    try {
      return CloudSession.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  @override
  set session(CloudSession? s) {
    if (s == null) {
      _prefs.remove(_kSession);
    } else {
      _prefs.setString(_kSession, jsonEncode(s.toJson()));
    }
  }

  @override
  String? get base => _prefs.getString(_kBase);

  @override
  set base(String? v) {
    if (v == null) {
      _prefs.remove(_kBase);
    } else {
      _prefs.setString(_kBase, v);
    }
  }

  @override
  bool get dirty => _prefs.getBool(_kDirty) ?? false;

  @override
  set dirty(bool v) => _prefs.setBool(_kDirty, v);
}
