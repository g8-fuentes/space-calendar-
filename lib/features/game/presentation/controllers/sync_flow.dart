import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar/google_calendar.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/services/calendar_import.dart';
import '../../domain/services/game_rules.dart';
import '../widgets/loading_overlay.dart';
import 'game_providers.dart';

/// Lê do Google Agenda os eventos com horário da semana atual e troca as
/// missões por eles. Devolve quantas missões vieram, ou null se o Google
/// ainda não deu permissão (só quando não é [interactive]).
Future<int?> _pull(WidgetRef ref, {required bool interactive}) async {
  final ctrl = ref.read(gameControllerProvider.notifier);
  final monday = mondayOf(ctrl.now);
  final raw = await ref
      .read(calendarSourceProvider)
      .fetchEvents(monday, monday.add(const Duration(days: 7)), interactive: interactive);
  if (raw == null) return null;
  final missions = toMissions(eventsFromGoogle(raw));
  ctrl.apply((s) {
    GameRules.importMissions(s, missions);
    s
      ..google = true
      ..lastSync = ctrl.now.millisecondsSinceEpoch;
  });
  return missions.length;
}

/// Conecta (ou sincroniza de novo) o Google Agenda com a tela de
/// carregamento. Com [heroName], conclui a tela inicial. Devolve o erro.
Future<String?> connectGoogle(BuildContext context, WidgetRef ref, {String? heroName}) async {
  final ctrl = ref.read(gameControllerProvider.notifier);
  try {
    // A conta e a permissão do Google aparecem por cima; a tela de
    // carregamento entra logo depois.
    final loading = Future<void>.delayed(const Duration(milliseconds: 400)).then<void>((_) async {
      if (context.mounted) await runLoading(context, 'SINCRONIZANDO A AGENDA', const Duration(milliseconds: 2200));
    });
    final n = await _pull(ref, interactive: true) ?? 0;
    await loading;
    if (heroName != null) {
      ctrl.apply((s) {
        s.name = heroName.trim().isEmpty ? 'Dev' : heroName.trim();
        s.onboarded = true;
        s.startDate = ymd(ctrl.now);
      });
    }
    Sfx.save.play();
    ctrl.notify([
      Notice(
        'AGENDA SINCRONIZADA!',
        n == 0
            ? 'Nenhum evento com horário nesta semana. Quando você criar eventos no Google Agenda, eles viram missões.'
            : 'Os $n eventos desta semana viraram missões. A agenda atualiza sozinha toda vez que você abre o app.',
        sound: 'none',
      ),
    ]);
    return null;
  } on CalendarSyncException catch (e) {
    Sfx.error.play();
    return e.message;
  } catch (e) {
    Sfx.error.play();
    return 'Não consegui falar com o Google Agenda ($e).';
  }
}

/// Sincroniza em silêncio (ao abrir ou voltar ao app), se o Google já
/// estiver conectado e a última vez tiver sido há mais de [minAge].
Future<void> autoSync(WidgetRef ref, {Duration minAge = const Duration(minutes: 10)}) async {
  final s = ref.read(gameControllerProvider);
  final now = ref.read(gameControllerProvider.notifier).now;
  if (!s.google) return;
  final fresh = now.millisecondsSinceEpoch - s.lastSync < minAge.inMilliseconds &&
      weekKeyOf(DateTime.fromMillisecondsSinceEpoch(s.lastSync)) == weekKeyOf(now);
  if (fresh) return;
  try {
    await _pull(ref, interactive: false);
  } catch (_) {
    // Sem rede ou sem permissão: fica com as missões que já tem.
  }
}

/// Desliga o Google Agenda. As missões e o progresso continuam.
Future<void> disconnectGoogle(WidgetRef ref) async {
  await ref.read(calendarSourceProvider).disconnect();
  ref.read(gameControllerProvider.notifier).apply((s) => s.google = false);
}
