import 'dart:convert';
import 'dart:io';

/// Tipo de tempo, para desenhar o céu.
enum Sky { clear, partly, cloudy, fog, drizzle, rain, storm }

/// Tempo agora em Bauru-SP (Open-Meteo, sem chave de API).
class WeatherNow {
  const WeatherNow(this.tempC, this.code);
  final double tempC;

  /// Código WMO do Open-Meteo.
  final int code;

  Sky get sky => skyOfCode(code);
  String get label => labelOfCode(code);
}

Sky skyOfCode(int c) => switch (c) {
      0 => Sky.clear,
      1 || 2 => Sky.partly,
      3 => Sky.cloudy,
      45 || 48 => Sky.fog,
      51 || 53 || 55 || 56 || 57 => Sky.drizzle,
      >= 95 => Sky.storm,
      >= 61 && <= 82 => Sky.rain,
      _ => Sky.cloudy,
    };

String labelOfCode(int c) => switch (c) {
      0 => 'céu limpo',
      1 => 'poucas nuvens',
      2 => 'parcialmente nublado',
      3 => 'nublado',
      45 || 48 => 'neblina',
      51 || 53 || 55 || 56 || 57 => 'garoa',
      61 || 63 || 80 || 81 => 'chuva',
      65 || 82 => 'chuva forte',
      66 || 67 => 'chuva gelada',
      >= 95 => 'tempestade',
      _ => 'nublado',
    };

const bauruLat = -22.3147, bauruLon = -49.0606;

/// Busca o tempo atual em Bauru. Devolve null sem internet.
Future<WeatherNow?> fetchBauruWeather() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$bauruLat',
      'longitude': '$bauruLon',
      'current': 'temperature_2m,weather_code',
      'timezone': 'America/Sao_Paulo',
    });
    final res = await (await client.getUrl(uri)).close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final cur = (jsonDecode(body) as Map)['current'] as Map;
    return WeatherNow((cur['temperature_2m'] as num).toDouble(), (cur['weather_code'] as num).toInt());
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
