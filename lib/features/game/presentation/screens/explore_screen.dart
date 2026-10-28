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
        PixelPanel(padding: EdgeInsets.zero, child: ExploreScene()),
        SizedBox(height: 12),
        _NextStop(),
        SizedBox(height: 12),
        _Board(),
      ],
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
          Text((s.name.isEmpty ? 'Dev' : s.name).toUpperCase(),
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
              ? 'Explorado! Na segunda-feira a nave parte para ${t.next.name}.'
              : 'Faltam ${t.missing} ${t.missing == 1 ? 'missão' : 'missões'} nesta semana para explorar '
                  '${t.place.name}. Depois: ${t.next.name}.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
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
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        Text('${dayNames[sel]}, ${two(date.day)}/${two(date.month)}${sel == today ? ' · hoje' : ''}',
            style: PixelText.body(15, color: Kanagawa.springViolet1)),
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
        if (sel == today && qs.isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: PixelButton(
              label: 'Marcar tudo até agora',
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              sound: false,
              onPressed: () {
                final ctrl = ref.read(gameControllerProvider.notifier);
                final n = ctrl.apply((g) => GameRules.markPastToday(g, ctrl.now));
                if (n > 0) {
                  ctrl.celebrate();
                  Sfx.done.play();
                  showToast(context, '$n missões marcadas');
                } else {
                  Sfx.click.play();
                  showToast(context, 'Nada para marcar até agora');
                }
              },
            ),
          ),
        ],
      ]),
    );
  }
}

class _DayChip extends ConsumerWidget {
  const _DayChip(
      {required this.day, required this.selected, required this.today, required this.done, required this.total});
  final int day, done, total;
  final bool selected, today;

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
            Text(total == 0 ? '–' : '$done/$total',
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
    final cat = categoryOf(mission.category);
    final color = Color(cat.color);
    return Semantics(
      checked: done,
      label: mission.title,
      child: Opacity(
        opacity: done && !live ? .6 : 1,
        child: Material(
          color: Kanagawa.sumiInk5,
          child: InkWell(
            onTap: () {
              final ctrl = ref.read(gameControllerProvider.notifier);
              final marked = ctrl.apply((g) => GameRules.toggle(g, mission, day, ctrl.now));
              if (marked) {
                ctrl.celebrate();
                Sfx.done.play();
              } else {
                Sfx.undo.play();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Kanagawa.sumiInk5,
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: live ? const [BoxShadow(color: Kanagawa.carpYellow, spreadRadius: 3)] : null,
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
                  child: done ? const Icon(Icons.check, size: 14, color: Kanagawa.sumiInk0) : null,
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
