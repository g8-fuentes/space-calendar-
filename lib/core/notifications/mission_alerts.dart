import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Um aviso semanal: dia (0 = segunda), hora de início e texto.
class Alert {
  const Alert({required this.key, required this.day, required this.minutes, required this.title, required this.body});
  final String key;
  final int day;
  final int minutes;
  final String title;
  final String body;

  /// Id estável para o Android (o mesmo aviso sempre substitui o anterior).
  int get id {
    var h = 17;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x3FFFFFFF;
    }
    return h;
  }
}

/// Notificações de início das missões. A versão de testes não faz nada.
abstract interface class MissionAlerts {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> replaceAll(List<Alert> alerts);
}

class NoMissionAlerts implements MissionAlerts {
  const NoMissionAlerts();
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> replaceAll(List<Alert> alerts) async {}
}

class LocalMissionAlerts implements MissionAlerts {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void>? _initializing;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'missoes',
      'Missões começando',
      channelDescription: 'Avisa quando o horário de uma missão começa.',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_rocket',
      color: Color(0xFFE6C384),
      category: AndroidNotificationCategory.reminder,
    ),
  );

  @override
  Future<void> init() => _initializing ??= _init();

  Future<void> _init() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      }
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_rocket')),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> replaceAll(List<Alert> alerts) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      final now = tz.TZDateTime.now(tz.local);
      for (final a in alerts.take(400)) {
        var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, a.minutes ~/ 60, a.minutes % 60)
            .add(Duration(days: (a.day - (now.weekday - 1) + 7) % 7));
        if (!at.isAfter(now)) at = at.add(const Duration(days: 7));
        await _plugin.zonedSchedule(
          id: a.id,
          title: a.title,
          body: a.body,
          scheduledDate: at,
          notificationDetails: _details,
          androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('Falha ao agendar notificações: $e');
    }
  }
}
