import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sound/sfx.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/calendar_import.dart';
import '../../domain/services/game_rules.dart';
import '../widgets/loading_overlay.dart';
import 'game_providers.dart';

enum ImportMode { intro, add, replace }

/// Lê um arquivo escolhido pela pessoa como texto. null = cancelou.
Future<(String name, String text)?> pickTextFile() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return null;
  final f = files.first;
  final bytes = await f.xFile.readAsBytes();
  return (f.name, utf8.decode(bytes, allowMalformed: true));
}

/// Fluxo completo de importação: escolher arquivo, tela de carregamento,
/// converter em missões e avisar o resultado. Devolve o erro, se houver.
Future<String?> importCalendar(BuildContext context, WidgetRef ref, ImportMode mode, {String? astronautName}) async {
  final picked = await pickTextFile();
  if (picked == null || !context.mounted) return null;
  final ctrl = ref.read(gameControllerProvider.notifier);
  final result = parseCalendar(picked.$1, picked.$2, ctrl.now);
  final missions = toMissions(result.events);
  final name = picked.$1.length > 22 ? '${picked.$1.substring(0, 22)}…' : picked.$1;
  await runLoading(context, 'IMPORTANDO ${name.toUpperCase()}', const Duration(milliseconds: 2600));
  if (result.error != null || missions.isEmpty) {
    Sfx.error.play();
    return result.error ??
        'Nenhum evento com horário foi encontrado. Confira se o arquivo é .ics, .cal ou .csv com título, dia e horário.';
  }
  ctrl.apply((s) {
    if (mode == ImportMode.intro) _finishIntro(s, astronautName, ctrl.now);
    GameRules.applyImport(s, missions, replace: mode == ImportMode.replace);
  });
  Sfx.save.play();
  final slots = missions.fold(0, (a, m) => a + m.days.length);
  final info = result.info;
  final skipped = [
    if (info.skippedAllDay > 0) '${info.skippedAllDay} de dia inteiro',
    if (info.skippedOld > 0) '${info.skippedOld} antigos ou encerrados',
    if (info.skippedOther > 0) '${info.skippedOther} sem horário ou inválidos',
  ];
  ctrl.notify([
    Notice(
      'CALENDÁRIO IMPORTADO!',
      '${missions.length} missões viraram $slots tarefas por semana.'
          '${skipped.isEmpty ? '' : ' Ignorei ${skipped.join(', ')}.'}'
          ' Você pode editar, excluir ou criar missões a qualquer momento.',
      sound: 'none',
    ),
  ]);
  return null;
}

void _finishIntro(GameState s, String? name, DateTime now) {
  s.name = (name ?? '').trim().isEmpty ? (s.name.isEmpty ? 'Astronauta' : s.name) : name!.trim();
  s.onboarded = true;
  s.startDate = ymd(now);
}

Future<void> startEmpty(WidgetRef ref, String name) async {
  final ctrl = ref.read(gameControllerProvider.notifier);
  ctrl.apply((s) => _finishIntro(s, name, ctrl.now));
  Sfx.save.play();
  final n = ref.read(gameControllerProvider).name;
  ctrl.notify([
    Notice('BEM-VINDO, ${n.toUpperCase()}!', 'Sua nave está pronta. Toque em + Nova missão para criar a primeira missão da semana.',
        sound: 'none'),
  ]);
}

Future<void> startDemo(BuildContext context, WidgetRef ref, String name) async {
  await runLoading(context, 'CARREGANDO EXEMPLO', const Duration(milliseconds: 1800));
  final ctrl = ref.read(gameControllerProvider.notifier);
  final (missions, courses) = demoSchedule();
  ctrl.apply((s) {
    _finishIntro(s, name, ctrl.now);
    s.courses = courses;
    GameRules.applyImport(s, missions, replace: true);
  });
  Sfx.save.play();
  final slots = missions.fold(0, (a, m) => a + m.days.length);
  ctrl.notify([
    Notice('CALENDÁRIO IMPORTADO!',
        '${missions.length} missões viraram $slots tarefas por semana. Você pode editar, excluir ou criar missões a qualquer momento.',
        sound: 'none'),
  ]);
}

// ---------- Google Agenda (endereço secreto iCal) ----------

Future<String> _download(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close().timeout(const Duration(seconds: 25));
    final body = await res.transform(const Utf8Decoder(allowMalformed: true)).join().timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    return body;
  } finally {
    client.close(force: true);
  }
}

/// Baixa a agenda do Google e troca as missões sincronizadas pelas da
/// semana atual. [quiet] roda sem tela de carregamento nem avisos (ao abrir
/// o app). Devolve o erro, se houver.
Future<String?> syncGoogleCalendar(
  BuildContext? context,
  WidgetRef ref, {
  String? url,
  bool quiet = false,
  String? astronautName,
}) async {
  final ctrl = ref.read(gameControllerProvider.notifier);
  final address = url ?? ref.read(gameControllerProvider).calendarUrl;
  if (address == null) return 'Conecte o Google Agenda primeiro.';
  final download = _download(address).then<(String?, Object?)>((t) => (t, null), onError: (Object e) => (null, e));
  if (!quiet && context != null && context.mounted) {
    await runLoading(context, 'SINCRONIZANDO GOOGLE AGENDA', const Duration(milliseconds: 1800));
  }
  final (text, error) = await download;
  String? fail;
  if (error != null || text == null) {
    fail = 'Não consegui baixar a agenda. Confira a internet e se o endereço secreto iCal está completo.';
  } else if (!RegExp('BEGIN:VCALENDAR', caseSensitive: false).hasMatch(text)) {
    fail = 'Esse endereço não é uma agenda iCal. Copie o "Endereço secreto no formato iCal", que termina em basic.ics.';
  }
  if (fail != null) {
    if (!quiet) Sfx.error.play();
    return fail;
  }
  final missions = toMissions(parseIcs(text!, ctrl.now, thisWeekOnly: true).events);
  final (total, added, removed) = ctrl.apply((s) {
    if (astronautName != null) _finishIntro(s, astronautName, ctrl.now);
    s.calendarUrl = address;
    s.lastSync = ctrl.now.millisecondsSinceEpoch;
    return GameRules.syncCalendar(s, missions);
  });
  if (quiet) return null;
  Sfx.save.play();
  ctrl.notify([
    Notice(
      'AGENDA SINCRONIZADA!',
      total == 0
          ? 'Conectado, mas não achei eventos com horário nesta semana. Eles aparecem quando você sincronizar de novo.'
          : '$total missões vêm do Google Agenda ($added novas, $removed removidas). '
              'O app sincroniza ao abrir, e você pode tocar em Sincronizar agenda quando quiser.',
      sound: 'none',
    ),
  ]);
  return null;
}

/// Desconecta. As missões que vieram da agenda ficam, como missões normais.
void disconnectGoogleCalendar(WidgetRef ref) {
  ref.read(gameControllerProvider.notifier).apply((s) {
    s.calendarUrl = null;
    s.lastSync = null;
    for (final m in s.missions) {
      m.synced = false;
    }
  });
  Sfx.delete.play();
}
