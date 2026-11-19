import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sessão de login: tokens do Supabase Auth.
class CloudSession {
  const CloudSession(
      {required this.accessToken, required this.refreshToken, required this.expiresAt, required this.email});

  final String accessToken;
  final String refreshToken;

  /// Segundos desde 1970.
  final int expiresAt;
  final String email;

  bool get expiringSoon => DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiresAt - 60;

  Map<String, Object?> toJson() => {'a': accessToken, 'r': refreshToken, 'x': expiresAt, 'e': email};

  factory CloudSession.fromJson(Map<String, Object?> j) => CloudSession(
        accessToken: j['a']! as String,
        refreshToken: j['r']! as String,
        expiresAt: (j['x']! as num).toInt(),
        email: j['e'] as String? ?? '',
      );

  factory CloudSession._fromAuth(Map<String, Object?> j, String fallbackEmail) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final user = j['user'] as Map?;
    return CloudSession(
      accessToken: j['access_token']! as String,
      refreshToken: j['refresh_token']! as String,
      expiresAt: (j['expires_at'] as num?)?.toInt() ?? now + ((j['expires_in'] as num?)?.toInt() ?? 3600),
      email: user?['email'] as String? ?? fallbackEmail,
    );
  }
}

/// O save guardado na nuvem e quando foi gravado.
class CloudSave {
  const CloudSave(this.state, this.updatedAt);
  final Map<String, Object?> state;
  final String updatedAt;
}

class CloudException implements Exception {
  const CloudException(this.message, {this.unauthorized = false, this.offline = false});
  final String message;
  final bool unauthorized;
  final bool offline;
  @override
  String toString() => message;
}

/// Cliente mínimo do Supabase (Auth + tabela `game_states`), só com HTTP,
/// para funcionar igual no Android e no navegador.
class CloudClient {
  CloudClient({required this.url, required this.anonKey, http.Client? client}) : _http = client ?? http.Client();

  final String url;
  final String anonKey;
  final http.Client _http;

  Map<String, String> _headers([String? token]) => {
        'apikey': anonKey,
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const CloudException('Sem conexão com a nuvem.', offline: true);
    }
  }

  Map<String, Object?> _json(http.Response r) {
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return d is Map ? d.cast<String, Object?>() : {'data': d};
    } catch (_) {
      return const {};
    }
  }

  CloudException _error(http.Response r) {
    final j = _json(r);
    final raw = (j['error_description'] ?? j['msg'] ?? j['message'] ?? j['error'] ?? '').toString();
    final code = (j['error_code'] ?? j['code'] ?? '').toString();
    final low = '$raw $code'.toLowerCase();
    final msg = switch (low) {
      _ when low.contains('invalid login') || low.contains('invalid_credentials') => 'E-mail ou senha incorretos.',
      _ when low.contains('not confirmed') => 'Confirme o e-mail pelo link que chegou na sua caixa de entrada.',
      _ when low.contains('already registered') || low.contains('user_already_exists') =>
        'Esse e-mail já tem conta. Use "Entrar".',
      _ when low.contains('password') && low.contains('6') => 'A senha precisa ter pelo menos 6 caracteres.',
      _ when low.contains('rate limit') => 'Muitas tentativas. Espere um pouco e tente de novo.',
      _ => raw.isEmpty ? 'A nuvem respondeu com erro ${r.statusCode}.' : raw,
    };
    return CloudException(msg, unauthorized: r.statusCode == 401);
  }

  /// Cria a conta. Devolve null quando o Supabase pede confirmação por e-mail.
  Future<CloudSession?> signUp(String email, String password) async {
    final r = await _send(() => _http.post(Uri.parse('$url/auth/v1/signup'),
        headers: _headers(), body: jsonEncode({'email': email, 'password': password})));
    if (r.statusCode >= 300) throw _error(r);
    final j = _json(r);
    if (j['access_token'] == null) return null;
    return CloudSession._fromAuth(j, email);
  }

  Future<CloudSession> signIn(String email, String password) async {
    final r = await _send(() => _http.post(Uri.parse('$url/auth/v1/token?grant_type=password'),
        headers: _headers(), body: jsonEncode({'email': email, 'password': password})));
    if (r.statusCode >= 300) throw _error(r);
    return CloudSession._fromAuth(_json(r), email);
  }

  Future<CloudSession> refresh(CloudSession s) async {
    final r = await _send(() => _http.post(Uri.parse('$url/auth/v1/token?grant_type=refresh_token'),
        headers: _headers(), body: jsonEncode({'refresh_token': s.refreshToken})));
    if (r.statusCode >= 300) {
      final e = _error(r);
      // Refresh token recusado: a sessão acabou.
      throw CloudException(e.message, unauthorized: r.statusCode >= 400 && r.statusCode < 500);
    }
    return CloudSession._fromAuth(_json(r), s.email);
  }

  Future<void> signOut(CloudSession s) async {
    try {
      await _send(() => _http.post(Uri.parse('$url/auth/v1/logout'), headers: _headers(s.accessToken)));
    } catch (_) {}
  }

  /// O save da conta, ou null se ainda não tem.
  Future<CloudSave?> fetch(CloudSession s) async {
    final r = await _send(() =>
        _http.get(Uri.parse('$url/rest/v1/game_states?select=state,updated_at'), headers: _headers(s.accessToken)));
    if (r.statusCode >= 300) throw _error(r);
    final rows = jsonDecode(utf8.decode(r.bodyBytes)) as List;
    if (rows.isEmpty) return null;
    final row = (rows.first as Map).cast<String, Object?>();
    return CloudSave((row['state']! as Map).cast<String, Object?>(), row['updated_at']! as String);
  }

  /// Grava o save (cria ou substitui) e devolve a data gravada.
  Future<String> push(CloudSession s, Map<String, Object?> state) async {
    final r = await _send(() => _http.post(
          Uri.parse('$url/rest/v1/game_states?on_conflict=user_id'),
          headers: {
            ..._headers(s.accessToken),
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
          body: jsonEncode({'state': state, 'updated_at': DateTime.now().toUtc().toIso8601String()}),
        ));
    if (r.statusCode >= 300) throw _error(r);
    final rows = jsonDecode(utf8.decode(r.bodyBytes)) as List;
    return ((rows.first as Map)['updated_at']! as String);
  }
}
