import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Falha ao falar com o Google Agenda, com uma mensagem para a pessoa.
class CalendarSyncException implements Exception {
  const CalendarSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Lê os eventos de uma semana direto do Google Agenda.
abstract class CalendarSource {
  /// Eventos (como vêm da API) de todas as agendas marcadas, entre
  /// [from] e [to]. Com [interactive], pede a conta e a permissão se
  /// precisar; sem, devolve null quando ainda não há permissão.
  Future<List<Map<String, Object?>>?> fetchEvents(DateTime from, DateTime to, {required bool interactive});

  /// Tira a permissão de leitura da agenda.
  Future<void> disconnect();
}

const _scope = 'https://www.googleapis.com/auth/calendar.readonly';
const _api = 'https://www.googleapis.com/calendar/v3';

/// Google Agenda pela conta Google do celular (só leitura). O app é
/// reconhecido pelo cliente OAuth Android do Google Cloud (pacote + SHA-1).
class GoogleCalendarSource implements CalendarSource {
  GoogleCalendarSource({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  Future<void>? _init;

  Future<void> _ready() => _init ??= GoogleSignIn.instance.initialize();

  Future<String?> _token({required bool interactive}) async {
    try {
      await _ready();
      final auth = GoogleSignIn.instance.authorizationClient;
      final a = await auth.authorizationForScopes(const [_scope]) ??
          (interactive ? await auth.authorizeScopes(const [_scope]) : null);
      return a?.accessToken;
    } on GoogleSignInException catch (e) {
      if (!interactive) return null;
      throw CalendarSyncException(switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Conexão com o Google cancelada.',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'O Google ainda não reconhece o app. Confira o cliente OAuth Android no Google Cloud '
              '(pacote e SHA-1) e se a Google Calendar API está ativada.',
        _ => 'Não consegui conectar ao Google (${e.description ?? e.code.name}).',
      });
    }
  }

  Future<Map<String, Object?>> _get(String token, String path, Map<String, String> query) async {
    final res = await _http.get(Uri.parse('$_api$path').replace(queryParameters: query),
        headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401) throw const _Expired();
    if (res.statusCode == 403) {
      throw const CalendarSyncException(
          'O Google recusou a leitura da agenda. Confira se a Google Calendar API está ativada no projeto '
          'e se a sua conta está nos usuários de teste.');
    }
    if (res.statusCode != 200) throw CalendarSyncException('O Google Agenda respondeu com erro ${res.statusCode}.');
    return (jsonDecode(res.body) as Map).cast<String, Object?>();
  }

  Future<List<Map<String, Object?>>> _read(String token, DateTime from, DateTime to) async {
    final cals = await _get(token, '/users/me/calendarList', {'minAccessRole': 'reader'});
    final ids = [
      for (final c in (cals['items'] as List? ?? const []).cast<Map<String, Object?>>())
        if (c['selected'] == true || c['primary'] == true) c['id'] as String,
    ];
    final out = <Map<String, Object?>>[];
    for (final id in ids) {
      String? page;
      for (var n = 0; n < 5; n++) {
        final r = await _get(token, '/calendars/${Uri.encodeComponent(id)}/events', {
          'timeMin': from.toUtc().toIso8601String(),
          'timeMax': to.toUtc().toIso8601String(),
          'singleEvents': 'true',
          'orderBy': 'startTime',
          'maxResults': '250',
          if (page != null) 'pageToken': page,
        });
        out.addAll([for (final e in (r['items'] as List? ?? const [])) (e as Map).cast<String, Object?>()]);
        page = r['nextPageToken'] as String?;
        if (page == null) break;
      }
    }
    return out;
  }

  @override
  Future<List<Map<String, Object?>>?> fetchEvents(DateTime from, DateTime to, {required bool interactive}) async {
    var token = await _token(interactive: interactive);
    if (token == null) return null;
    try {
      try {
        return await _read(token, from, to);
      } on _Expired {
        // Permissão vencida: limpa o token guardado e tenta de novo uma vez.
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
        token = await _token(interactive: interactive);
        if (token == null) return null;
        return await _read(token, from, to);
      }
    } on _Expired {
      throw const CalendarSyncException('A permissão do Google venceu. Conecte de novo.');
    } on CalendarSyncException {
      rethrow;
    } catch (_) {
      throw const CalendarSyncException('Sem conexão com o Google Agenda agora. Tente de novo mais tarde.');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _ready();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Sem conta conectada: nada a desfazer.
    }
  }
}

class _Expired implements Exception {
  const _Expired();
}
