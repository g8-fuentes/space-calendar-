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
import '../widgets/google_connect.dart';
import '../widgets/hud.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/space_scene.dart';
import '../widgets/ui.dart';
import 'mission_form.dart';

/// Tela principal: HUD, cena com o inimigo do nível, missões da semana e perfil.
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: const [
        Hud(),
        SizedBox(height: 14),
        _SceneCard(),
        SizedBox(height: 14),
        _QuestBoard(),
        SizedBox(height: 14),
        _Profile(),
      ],
    );
  }
}

class _SceneCard extends ConsumerWidget {
  const _SceneCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final today = dayIndexOf(now), mm = minutesOfDay(now);
    final slots = daySlots(s, today);
    final live = slots.where((q) {
      final a = minutesOf(q.start), b = minutesOf(q.end);
      return a != null && b != null && mm >= a && mm < b;
    }).toList();
    Mission? next;
    for (final q in slots) {
      final a = minutesOf(q.start);
      if (a != null && a > mm) {
        next = q;
        break;
      }
    }
    final nowText = live.isNotEmpty
        ? live.map((q) => q.title).join(' + ')
        : next != null
            ? 'livre · ${next.title} às ${next.start}'
            : (s.missions.isEmpty ? 'sem missões ainda' : 'dia encerrado');
    final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
    final energy = slots.isEmpty ? 0.0 : dayDone(s, w, today) / slots.length;
    final foe = t.enemy;
    return PixelPanel(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SpaceScene(),
        const SizedBox(height: 8),
        _line([
          Flexible(child: Text.rich(TextSpan(style: PixelText.body(14, color: Kanagawa.springViolet1), children: [
            const TextSpan(text: 'Inimigo do nível: '),
            TextSpan(text: foe.name, style: PixelText.body(14, color: Kanagawa.sakuraPink)),
          ]))),
          Text('${foe.boss ? 'Chefe · ' : ''}nível ${t.lv}', style: PixelText.body(14, color: Kanagawa.springViolet1)),
        ]),
        const SizedBox(height: 4),
        _line([
          Flexible(child: Text.rich(TextSpan(style: PixelText.body(15), children: [
            const TextSpan(text: 'Agora: '),
            TextSpan(text: nowText, style: PixelText.body(15, color: Kanagawa.carpYellow)),
          ]))),
          Text('${dayNames[today]} ${two(now.hour)}:${two(now.minute)}', style: PixelText.body(15)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('Combustível de hoje', style: PixelText.body(14)),
          const SizedBox(width: 10),
          Expanded(child: PixelBar(value: energy, color: Kanagawa.springGreen)),
          const SizedBox(width: 10),
          Text('${(energy * 100).round()}%', style: PixelText.body(14)),
        ]),
      ]),
    );
  }

  Widget _line(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          children[0],
          const SizedBox(width: 8),
          children[1],
        ]),
      );
}

class _QuestBoard extends ConsumerWidget {
  const _QuestBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final sel = ref.watch(selectedDayProvider);
    final today = dayIndexOf(now);
    final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
    final qs = daySlots(s, sel);
    final mm = minutesOfDay(now);
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _DayButton(day: i, selected: i == sel, today: i == today, ratio: _ratio(s, w, i))),
          ],
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text('${dayNames[sel]}${sel == today ? ' · hoje' : ''}'.toUpperCase(), style: PixelText.display(10))),
          Text('${dayDone(s, w, sel)}/${qs.length} missões', style: PixelText.body(15, color: Kanagawa.springViolet1)),
        ]),
        const SizedBox(height: 10),
        if (qs.isEmpty)
          EmptyBox('Nenhuma missão na ${dayNames[sel].toLowerCase()}.', 'Crie uma missão ou importe um calendário em Mais › Ajustes.')
        else
          for (final m in qs) ...[
            _QuestTile(
              mission: m,
              day: sel,
              done: w.done.containsKey(slotKey(m, sel)),
              live: sel == today && _isLive(m, mm),
            ),
            const SizedBox(height: 6),
          ],
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          PixelButton(label: '+ Nova missão', onPressed: () => openMissionForm(context, presetDay: sel)),
          PixelButton(
            label: s.calendarUrl == null ? 'Conectar Google Agenda' : 'Sincronizar agenda',
            color: Kanagawa.springBlue,
            onPressed: () => syncOrConnect(context, ref),
          ),
          if (sel == today && qs.isNotEmpty)
            PixelButton(
              label: 'Marcar tudo até agora',
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              sound: false,
              onPressed: () {
                final ctrl = ref.read(gameControllerProvider.notifier);
                final n = ctrl.apply((g) => GameRules.markPastToday(g, ctrl.now));
                if (n > 0) {
                  ctrl.celebrate(0);
                  Sfx.done.play();
                  showToast(context, '$n missões marcadas');
                } else {
                  Sfx.click.play();
                  showToast(context, 'Nada para marcar até agora');
                }
              },
            ),
        ]),
      ]),
    );
  }

  static double _ratio(GameState s, WeekRecord w, int d) {
    final tot = daySlots(s, d).length;
    return tot == 0 ? 0 : dayDone(s, w, d) / tot;
  }

  static bool _isLive(Mission m, int mm) {
    final a = minutesOf(m.start), b = minutesOf(m.end);
    return a != null && b != null && mm >= a && mm < b;
  }
}

class _DayButton extends ConsumerWidget {
  const _DayButton({required this.day, required this.selected, required this.today, required this.ratio});
  final int day;
  final bool selected;
  final bool today;
  final double ratio;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
        button: true,
        selected: selected,
        label: dayNames[day],
        child: InkWell(
          onTap: () {
            Sfx.click.play();
            ref.read(selectedDayProvider.notifier).state = day;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? Kanagawa.carpYellow : Kanagawa.sumiInk5,
              border: Border.all(color: today ? Kanagawa.springBlue : Kanagawa.sumiInk0, width: 3),
            ),
            child: Column(children: [
              Text(dayAbbr[day], style: PixelText.display(7, color: selected ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
              const SizedBox(height: 6),
              FractionallySizedBox(widthFactor: .7, child: PixelBar(value: ratio, height: 5, color: Kanagawa.springGreen)),
            ]),
          ),
        ),
      );
}

class _QuestTile extends ConsumerWidget {
  const _QuestTile({required this.mission, required this.day, required this.done, required this.live});
  final Mission mission;
  final int day;
  final bool done;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final cat = categoryOf(mission.category);
    final color = Color(cat.color);
    final base = questXp(mission);
    final xp = (base * (s.boostCharges > 0 ? 1.5 : 1)).round();
    final coins = questCoins(base) * (s.magnetCharges > 0 ? 2 : 1);
    final link = s.course(mission.link);
    return Semantics(
      checked: done,
      label: mission.title,
      child: Opacity(
        opacity: done && !live ? .6 : 1,
        child: Material(
          color: Kanagawa.sumiInk5,
          child: InkWell(
            onTap: () => _toggle(context, ref),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: live ? const [BoxShadow(color: Kanagawa.carpYellow, spreadRadius: 3)] : null,
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
              child: Row(children: [
                SizedBox(
                  width: 44,
                  child: Text(mission.start.isEmpty ? 'livre' : mission.start,
                      style: PixelText.body(14, color: Kanagawa.springViolet1)),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: done ? Kanagawa.springGreen : Kanagawa.sumiInk0,
                    border: Border.all(color: done ? Kanagawa.sumiInk0 : Kanagawa.springViolet1, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mission.title,
                        style: PixelText.body(16).copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationThickness: 2,
                        )),
                    Text.rich(TextSpan(style: PixelText.body(12, color: color), children: [
                      TextSpan(text: cat.name),
                      if (link != null) TextSpan(text: ' · ${link.name}', style: PixelText.body(12, color: Kanagawa.carpYellow)),
                      if (mission.synced) TextSpan(text: ' · Google', style: PixelText.body(12, color: Kanagawa.springViolet1)),
                      if (live) TextSpan(text: ' · AGORA', style: PixelText.display(6, color: Kanagawa.carpYellow)),
                    ])),
                  ]),
                ),
                const SizedBox(width: 6),
                Text('+${xp}XP\n+$coins¢', textAlign: TextAlign.right, style: PixelText.display(6, color: Kanagawa.springBlue)),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Sfx.click.play();
                    openMissionForm(context, mission: mission);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    color: Kanagawa.sumiInk0,
                    child: Text('EDITAR', style: PixelText.display(6, color: Kanagawa.springViolet1)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final before = ref.read(gameControllerProvider);
    final rec = ctrl.apply((s) => GameRules.toggle(s, mission, day, ctrl.now));
    if (rec == null) {
      Sfx.undo.play();
      showToast(context, 'Missão desmarcada: ${mission.title}');
      return;
    }
    ctrl.celebrate(rec.xp);
    Sfx.done.play();
    final s = ref.read(gameControllerProvider);
    final w = s.week(weekKeyOf(ctrl.now));
    final link = before.course(mission.link);
    if (daySlots(s, day).every((m) => w.done.containsKey(slotKey(m, day)))) {
      showToast(context, 'DIA COMPLETO! ${dayNames[day]} zerado');
    } else {
      showToast(context, '+${rec.xp} XP  +${rec.coins} moedas${link != null ? ' · ${link.name} +${rec.xp} XP' : ''}');
    }
  }
}

class _Profile extends ConsumerWidget {
  const _Profile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final ri = t.rankIndex;
    final start = ri - 2 < 0 ? 0 : ri - 2;
    final next = rankAt(ri + 1);
    final mk = t.suitMk;
    final w = s.weeks[weekKeyOf(now)] ?? WeekRecord();
    final attrs = <(Category, int, int)>[];
    for (final c in categories) {
      var tot = 0, dn = 0;
      for (final m in s.missions.where((m) => m.category == c.key)) {
        for (final d in m.days) {
          tot++;
          if (w.done.containsKey(slotKey(m, d))) dn++;
        }
      }
      if (tot > 0) attrs.add((c, dn, tot));
    }
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Rank'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.6,
          children: [
            for (var i = start; i < start + 6; i++) _RankTile(rank: rankAt(i), got: i <= ri, current: i == ri),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Próximo rank: ${next.name} no nível ${next.level} (faltam ${next.level - t.lv}). Traje Mk $mk; o Mk ${mk + 1} chega no nível ${mk * 5 + 1}.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        const SizedBox(height: 14),
        const SectionTitle('Modos do traje'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.4,
          children: [for (final m in suitModes) _ModeTile(mode: m, active: s.suitMode == m.id, unlocked: t.modeUnlocked(m))],
        ),
        const SizedBox(height: 14),
        const SectionTitle('Atributos da semana'),
        const SizedBox(height: 8),
        if (attrs.isEmpty)
          Text('Os atributos aparecem quando houver missões.', style: PixelText.body(14, color: Kanagawa.springViolet1))
        else
          for (final (c, dn, tot) in attrs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 104, child: Text(c.name, style: PixelText.body(15))),
                Expanded(child: PixelBar(value: dn / tot, color: Color(c.color))),
                SizedBox(
                    width: 52,
                    child: Text('$dn/$tot', textAlign: TextAlign.right, style: PixelText.body(14, color: Kanagawa.springViolet1))),
              ]),
            ),
      ]),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.got, required this.current});
  final Rank rank;
  final bool got;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = Color(rank.color);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: got ? c : Kanagawa.sumiInk5,
        border: current ? Border.all(color: Kanagawa.fujiWhite, width: 3) : Border(bottom: BorderSide(color: c, width: 4)),
      ),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(rank.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PixelText.body(12, color: got ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite).copyWith(height: 1.1)),
        Text('LV ${rank.level}', style: PixelText.body(11, color: got ? Kanagawa.sumiInk0 : Kanagawa.springViolet1)),
      ]),
    );
  }
}

class _ModeTile extends ConsumerWidget {
  const _ModeTile({required this.mode, required this.active, required this.unlocked});
  final SuitMode mode;
  final bool active;
  final bool unlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Color(mode.color);
    return Opacity(
      opacity: unlocked ? 1 : .55,
      child: Material(
        color: active ? c : Kanagawa.sumiInk5,
        child: InkWell(
          onTap: unlocked
              ? () {
                  ref.read(gameControllerProvider.notifier).apply((s) => s.suitMode = mode.id);
                  Sfx.power.play();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(mode.name.toUpperCase(),
                  textAlign: TextAlign.center, style: PixelText.display(7, color: active ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
              const SizedBox(height: 4),
              Text(unlocked ? 'liberado' : mode.description,
                  textAlign: TextAlign.center,
                  style: PixelText.body(11, color: active ? Kanagawa.sumiInk0 : Kanagawa.springViolet1)),
            ]),
          ),
        ),
      ),
    );
  }
}
