import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sound/sfx.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/services/calendar_import.dart';
import '../../domain/services/game_rules.dart';
import '../widgets/loading_overlay.dart';
import 'game_providers.dart';

/// Lê o arquivo escolhido pela pessoa como texto. null = cancelou.
Future<(String name, String text)?> pickTextFile() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return null;
  final f = files.first;
  final bytes = await f.xFile.readAsBytes();
  return (f.name, utf8.decode(bytes, allowMalformed: true));
}

/// Importa uma agenda .ics/.cal: escolher o arquivo, tela de carregamento,
/// trocar as missões e avisar o resultado. Com [heroName], conclui a
/// tela inicial. Devolve o erro, se houver.
Future<String?> importCalendar(BuildContext context, WidgetRef ref, {String? heroName}) async {
  final picked = await pickTextFile();
  if (picked == null || !context.mounted) return null;
  final ctrl = ref.read(gameControllerProvider.notifier);
  final result = parseCalendar(picked.$1, picked.$2, ctrl.now);
  final missions = toMissions(result.events);
  final name = picked.$1.length > 22 ? '${picked.$1.substring(0, 22)}…' : picked.$1;
  await runLoading(context, 'LENDO ${name.toUpperCase()}', const Duration(milliseconds: 2400));
  if (result.error != null || missions.isEmpty) {
    Sfx.error.play();
    return result.error ?? 'Nenhum evento com horário foi encontrado nessa agenda.';
  }
  ctrl.apply((s) {
    if (heroName != null) {
      s.name = heroName.trim().isEmpty ? 'Dev' : heroName.trim();
      s.onboarded = true;
      s.startDate = ymd(ctrl.now);
    }
    GameRules.importMissions(s, missions);
  });
  Sfx.save.play();
  final slots = missions.fold(0, (a, m) => a + m.days.length);
  final info = result.info;
  final skipped = [
    if (info.skippedAllDay > 0) '${info.skippedAllDay} de dia inteiro',
    if (info.skippedOld > 0) '${info.skippedOld} antigos',
    if (info.skippedOther > 0) '${info.skippedOther} sem horário',
  ];
  ctrl.notify([
    Notice(
      'AGENDA CARREGADA!',
      '${missions.length} eventos viraram $slots missões por semana.'
          '${skipped.isEmpty ? '' : ' Ignorei ${skipped.join(', ')}.'}'
          ' Marque cada missão concluída para levar o personagem mais longe.',
      sound: 'none',
    ),
  ]);
  return null;
}
