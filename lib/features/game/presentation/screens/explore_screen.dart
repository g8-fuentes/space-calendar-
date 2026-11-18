import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/explore_scene.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';
import 'map_screen.dart';
import 'week_screen.dart';

/// Tela principal: a cena da exploração e as missões da agenda, que só
/// podem ser marcadas como concluídas (ou desmarcadas).
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: const [
        _Header(),
        SizedBox(height: 10),
        NowCard(),
        SizedBox(height: 12),
        PixelPanel(padding: EdgeInsets.zero, child: ExploreScene()),
        SizedBox(height: 12),
        _NextStop(),
        SizedBox(height: 12),
        _Board(),
        SizedBox(height: 14),
        WeekSummary(),
      ],
    );
  }
}

/// Marca ou desmarca a missão e mostra o aviso com DESFAZER.
void toggleMission(BuildContext context, WidgetRef ref, Mission m, int day) {
  final ctrl = ref.read(gameControllerProvider.notifier);
  final marked = ctrl.apply((g) => GameRules.toggle(g, m, day, ctrl.now));
  if (marked) {
    ctrl.celebrate();
    Sfx.done.play();
  } else {
    Sfx.undo.play();
  }
  showToast(context, marked ? 'Concluída: ${m.title}' : 'Desmarcada: ${m.title}', onUndo: () {
    ctrl.apply((g) => GameRules.toggle(g, m, day, ctrl.now));
    Sfx.undo.play();
  });
}

/// O que fazer agora: a missão em andamento, a que ficou para trás ou a
/// próxima de hoje, com um botão grande para concluir.
class NowCard extends ConsumerWidget {
  const NowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final today = dayIndexOf(now), mm = minutesOfDay(now);
    final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
    final qs = daySlots(s, today);
    final open = [
      for (final m in qs)
        if (!w.done.containsKey(slotKey(m, today))) m
    ];
    final skipped = w.skipped.contains(today);

    Mission? pick;
    var tag = '';
    for (final m in open) {
      final a = minutesOf(m.start), b = minutesOf(m.end);
      if (a != null && b != null && mm >= a && mm < b) {
        pick = m;
        tag = 'AGORA';
        break;
      }
    }
    if (pick == null) {
      for (final m in open) {
        final a = minutesOf(m.start);
        if (a == null || a <= mm) {
          pick = m;
          tag = a == null ? 'HOJE' : 'FICOU PARA TRÁS';
          break;
        }
      }
    }
    if (pick == null) {
      for (final m in open) {
        pick = m;
        tag = 'PRÓXIMA ÀS ${m.start}';
        break;
      }
    }

    final String title, sub;
    if (s.missions.isEmpty) {
      return const SizedBox.shrink();
    } else if (skipped) {
      title = 'Hoje está pulado.';
      sub = 'As missões de hoje não contam na meta da semana. Descanse.';
    } else if (qs.isEmpty) {
      title = 'Dia livre.';
      sub = 'Nenhuma missão na agenda hoje.';
    } else if (pick == null) {
      title = 'Dia completo!';
      sub = 'Todas as ${qs.length} missões de hoje estão feitas.';
    } else {
      title = pick.title;
      sub = '${pick.start.isEmpty ? 'sem horário' : pick.start}${pick.end.isEmpty ? '' : ' às ${pick.end}'}'
          ' · faltam ${open.length} de ${qs.length} hoje';
    }
    final mission = pick;
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(mission == null || skipped ? 'HOJE' : tag, style: PixelText.display(8, color: Kanagawa.carpYellow)),
        const SizedBox(height: 6),
        Text(title, style: PixelText.display(11), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(sub, style: PixelText.body(14, color: Kanagawa.springViolet1)),
        if (mission != null && !skipped) ...[
          const SizedBox(height: 10),
          PixelButton(
            label: 'Concluir',
            sound: false,
            onPressed: () => toggleMission(context, ref, mission, today),
          ),
        ],
      ]),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    Widget chip(String label, bool on, VoidCallback tap) => Semantics(
          button: true,
          toggled: on,
          child: InkWell(
            onTap: tap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: on ? Kanagawa.sumiInk5 : Kanagawa.sumiInk0,
              child: Text('$label ${on ? 'ON' : 'OFF'}',
                  style: PixelText.display(6, color: on ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            ),
          ),
        );
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((s.name.isEmpty ? t.form.name : s.name).toUpperCase(),
              style: PixelText.display(10), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
              '${t.missionsDone} ${t.missionsDone == 1 ? 'missão concluída' : 'missões concluídas'} · hoje ${t.doneToday}/${t.totalToday}',
              style: PixelText.body(14, color: Kanagawa.springViolet1)),
        ]),
      ),
      chip('MÚSICA', s.music, () {
        Sfx.click.play();
        ctrl.apply((g) => g.music = !g.music);
      }),
      const SizedBox(width: 6),
      chip('SOM', s.sound, () {
        ctrl.apply((g) => g.sound = !g.sound);
        Sfx.click.play();
      }),
    ]);
  }
}

class _NextStop extends ConsumerWidget {
  const _NextStop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('SEMANA ${t.place.week} · EXPLORANDO',
                  style: PixelText.display(8, color: Kanagawa.springViolet1))),
          Text('${t.weekDone}/${t.weekGoal} missões', style: PixelText.body(14, color: Kanagawa.carpYellow)),
        ]),
        const SizedBox(height: 4),
        Text(t.place.name, style: PixelText.display(11)),
        const SizedBox(height: 8),
        PixelBar(value: t.progress, color: t.explored ? Kanagawa.carpYellow : Kanagawa.springGreen, height: 14),
        const SizedBox(height: 6),
        Text(
          t.explored
              ? 'Explorado! Na segunda-feira você entra em ${t.next.name}.'
              : 'Faltam ${t.missing} ${t.missing == 1 ? 'missão' : 'missões'} nesta semana para explorar '
                  '${t.place.name}. Depois: ${t.next.name}.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PixelButton(
            label: 'Ver mapa da jornada',
            color: Kanagawa.sumiInk5,
            textColor: Kanagawa.fujiWhite,
            onPressed: () => openMap(context),
          ),
        ),
      ]),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board();

  static bool _isLive(Mission m, int mm) {
    final a = minutesOf(m.start), b = minutesOf(m.end);
    return a != null && b != null && mm >= a && mm < b;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final today = dayIndexOf(now), mm = minutesOfDay(now);
    final sel = ref.watch(selectedDayProvider);
    final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
    final qs = daySlots(s, sel);
    final date = dateOf(weekKeyOf(now), sel);
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('MISSÕES DA SEMANA', style: PixelText.display(10)),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _DayChip(
                day: i,
                selected: i == sel,
                today: i == today,
                done: dayDone(s, w, i),
                total: daySlots(s, i).length,
                skipped: w.skipped.contains(i),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        Text('${dayNames[sel]}, ${two(date.day)}/${two(date.month)}${sel == today ? ' · hoje' : ''}',
            style: PixelText.body(15, color: Kanagawa.springViolet1)),
        if (w.skipped.contains(sel)) ...[
          const SizedBox(height: 4),
          Text('Dia pulado: as missões dele não contam na meta da semana.',
              style: PixelText.body(14, color: Kanagawa.carpYellow)),
        ],
        const SizedBox(height: 8),
        if (s.missions.isEmpty)
          const EmptyBox('Nenhuma agenda importada.', 'Vá em Ajustes e importe o arquivo .ics ou .cal da sua agenda.')
        else if (qs.isEmpty)
          const EmptyBox('Dia livre.', 'Nenhuma missão na agenda neste dia.')
        else
          for (final m in qs) ...[
            _MissionTile(
              mission: m,
              day: sel,
              done: w.done.containsKey(slotKey(m, sel)),
              live: sel == today && _isLive(m, mm),
            ),
            const SizedBox(height: 6),
          ],
        if (qs.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (sel == today)
              PixelButton(
                label: 'Marcar tudo até agora',
                color: Kanagawa.sumiInk5,
                textColor: Kanagawa.fujiWhite,
                sound: false,
                onPressed: () {
                  final ctrl = ref.read(gameControllerProvider.notifier);
                  final key = weekKeyOf(ctrl.now);
                  final before = {...?ref.read(gameControllerProvider).weeks[key]?.done.keys};
                  final n = ctrl.apply((g) => GameRules.markPastToday(g, ctrl.now));
                  if (n > 0) {
                    ctrl.celebrate();
                    Sfx.done.play();
                    showToast(context, '$n ${n == 1 ? 'missão marcada' : 'missões marcadas'}', onUndo: () {
                      ctrl.apply((g) => g.weeks[key]?.done.removeWhere((k, _) => !before.contains(k)));
                      Sfx.undo.play();
                    });
                  } else {
                    Sfx.click.play();
                    showToast(context, 'Nada para marcar até agora');
                  }
                },
              ),
            PixelButton(
              label: w.skipped.contains(sel)
                  ? 'Voltar a contar ${sel == today ? 'hoje' : 'este dia'}'
                  : (sel == today ? 'Hoje não dá' : 'Pular este dia'),
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              sound: false,
              onPressed: () {
                final ctrl = ref.read(gameControllerProvider.notifier);
                final skipped = ctrl.apply((g) => GameRules.toggleSkip(g, sel, ctrl.now));
                Sfx.click.play();
                showToast(
                    context,
                    skipped
                        ? '${dayNames[sel]} pulado. A meta da semana diminuiu.'
                        : '${dayNames[sel]} volta a contar.',
                    onUndo: () => ctrl.apply((g) => GameRules.toggleSkip(g, sel, ctrl.now)));
              },
            ),
          ]),
        ],
      ]),
    );
  }
}

class _DayChip extends ConsumerWidget {
  const _DayChip(
      {required this.day,
      required this.selected,
      required this.today,
      required this.done,
      required this.total,
      this.skipped = false});
  final int day, done, total;
  final bool selected, today, skipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = total > 0 && done >= total;
    return Semantics(
      button: true,
      selected: selected,
      label: '${dayNames[day]}: $done de $total',
      child: InkWell(
        onTap: () {
          Sfx.click.play();
          ref.read(selectedDayProvider.notifier).state = day;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Kanagawa.springBlue : Kanagawa.sumiInk0,
            border: Border.all(color: today ? Kanagawa.carpYellow : Colors.transparent, width: 2),
          ),
          child: Column(children: [
            Text(dayAbbr[day], style: PixelText.display(6, color: selected ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
            const SizedBox(height: 2),
            Text(total == 0 ? '–' : (skipped ? 'pulo' : '$done/$total'),
                style: PixelText.body(12,
                    color: selected ? Kanagawa.sumiInk0 : (full ? Kanagawa.springGreen : Kanagawa.springViolet1))),
          ]),
        ),
      ),
    );
  }
}

class _MissionTile extends ConsumerWidget {
  const _MissionTile({required this.mission, required this.day, required this.done, required this.live});
  final Mission mission;
  final int day;
  final bool done, live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = categoryOf(fixCategory(mission.category, mission.title));
    final color = Kanagawa.ink(Color(cat.color));
    return Semantics(
      checked: done,
      label: mission.title,
      child: Opacity(
        opacity: done && !live ? .6 : 1,
        child: Material(
          color: Kanagawa.sumiInk5,
          child: InkWell(
            onTap: () => toggleMission(context, ref, mission, day),
            child: Container(
              decoration: BoxDecoration(
                color: Kanagawa.sumiInk5,
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: live ? [BoxShadow(color: Kanagawa.carpYellow, spreadRadius: 3)] : null,
              ),
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                SizedBox(
                  width: 50,
                  child: Text(mission.start.isEmpty ? 'livre' : mission.start,
                      style: PixelText.body(15, color: Kanagawa.springViolet1)),
                ),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? Kanagawa.springGreen : Kanagawa.sumiInk0,
                    border: Border.all(color: done ? Kanagawa.sumiInk0 : Kanagawa.springViolet1, width: 2),
                  ),
                  child: done ? Icon(Icons.check, size: 14, color: Kanagawa.sumiInk0) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mission.title,
                        style: PixelText.body(17)
                            .copyWith(decoration: done ? TextDecoration.lineThrough : null, decorationThickness: 2)),
                    Text.rich(TextSpan(style: PixelText.body(13, color: color), children: [
                      TextSpan(text: cat.name),
                      if (mission.end.isNotEmpty)
                        TextSpan(
                            text: ' · até ${mission.end}', style: PixelText.body(13, color: Kanagawa.springViolet1)),
                      if (live) TextSpan(text: ' · AGORA', style: PixelText.display(6, color: Kanagawa.carpYellow)),
                    ])),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
