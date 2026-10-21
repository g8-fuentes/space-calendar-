import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/schedule.dart';
import '../../domain/entities/quest.dart';
import '../controllers/game_providers.dart';
import '../widgets/course_row.dart';
import '../widgets/event_presenter.dart';
import '../widgets/hud.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/space_scene.dart';

final selectedDayProvider = StateProvider<int?>((ref) => null);

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final today = dayIndexOf(now);
    final selected = ref.watch(selectedDayProvider) ?? today;
    final state = ref.watch(gameControllerProvider);
    final week = state.week(weekKeyOf(now));
    final day = weeklySchedule[selected];
    final minute = minutesOfDay(now);
    final doneCount = day.quests.where((q) => week.done.containsKey(q.id)).length;
    final todayQuests = weeklySchedule[today].quests;
    final fuel = todayQuests.where((q) => week.done.containsKey(q.id)).length / todayQuests.length;
    final live = todayQuests.where((q) => q.isLiveAt(minute)).map((q) => q.title).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Hud(),
          const SizedBox(height: 14),
          PixelPanel(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SpaceScene(),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Agora: '),
                  TextSpan(
                    text: live.isEmpty ? 'livre' : live.join(' + '),
                    style: const TextStyle(color: Kanagawa.carpYellow),
                  ),
                ]),
                style: PixelText.body(15),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Text('Combustível de hoje', style: PixelText.body(13)),
                const SizedBox(width: 8),
                Expanded(child: PixelBar(value: fuel, color: Kanagawa.springGreen)),
                const SizedBox(width: 8),
                Text('${(fuel * 100).round()}%', style: PixelText.body(13)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          _DayPicker(selected: selected, today: today, done: week.done),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SectionTitle('${day.name}${selected == today ? ' · hoje' : ''}', color: Kanagawa.fujiWhite)),
            Text('$doneCount/${day.quests.length} missões', style: PixelText.body(14, color: Kanagawa.springViolet1)),
          ]),
          const SizedBox(height: 10),
          for (final q in day.quests) ...[
            _QuestTile(
              quest: q,
              done: week.done.containsKey(q.id),
              live: selected == today && q.isLiveAt(minute),
            ),
            const SizedBox(height: 6),
          ],
          if (selected == today) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(
                label: 'Marcar tudo até agora',
                color: Kanagawa.sumiInk5,
                textColor: Kanagawa.fujiWhite,
                onPressed: () async {
                  final events = ref.read(gameControllerProvider.notifier).markPastToday();
                  showGameToast(context, 'Missões até agora marcadas');
                  await presentEvents(context, events);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.selected, required this.today, required this.done});
  final int selected;
  final int today;
  final Map<String, int> done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      for (var i = 0; i < weeklySchedule.length; i++) ...[
        if (i > 0) const SizedBox(width: 5),
        Expanded(
          child: Semantics(
            selected: i == selected,
            button: true,
            child: InkWell(
              onTap: () => ref.read(selectedDayProvider.notifier).state = i,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: i == selected ? Kanagawa.carpYellow : Kanagawa.sumiInk5,
                  border: Border.all(color: i == today ? Kanagawa.springBlue : Kanagawa.sumiInk0, width: 3),
                ),
                child: Column(children: [
                  Text(weeklySchedule[i].short,
                      style: PixelText.display(7, color: i == selected ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: PixelBar(
                      height: 5,
                      color: Kanagawa.springGreen,
                      value: weeklySchedule[i].quests.where((q) => done.containsKey(q.id)).length /
                          weeklySchedule[i].quests.length,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _QuestTile extends ConsumerStatefulWidget {
  const _QuestTile({required this.quest, required this.done, required this.live});
  final Quest quest;
  final bool done;
  final bool live;

  @override
  ConsumerState<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends ConsumerState<_QuestTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final color = Kanagawa.category(q.category);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        checked: widget.done,
        label: '${q.start} ${q.title}',
        child: Material(
          color: widget.done ? Kanagawa.sumiInk4 : Kanagawa.sumiInk5,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: widget.live ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
          ),
          child: InkWell(
            onTap: () async {
              final (marked, events) = ref.read(gameControllerProvider.notifier).toggleQuest(q.id);
              showGameToast(context, marked ? '+${q.xp} XP  +${q.coins} moedas · ${q.title}' : 'Missão desmarcada');
              await presentEvents(context, events);
            },
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 5))),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(children: [
                SizedBox(width: 46, child: Text(q.start, style: PixelText.body(14, color: Kanagawa.springViolet1))),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: widget.done ? Kanagawa.springGreen : Kanagawa.sumiInk0,
                    border: Border.all(color: widget.done ? Kanagawa.sumiInk0 : Kanagawa.springViolet1, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: widget.done ? .6 : 1,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        q.title,
                        style: PixelText.body(16).copyWith(
                          decoration: widget.done ? TextDecoration.lineThrough : null,
                          decorationThickness: 2,
                        ),
                      ),
                      Text('${q.category.attribute}${widget.live ? ' · AGORA' : ''}',
                          style: PixelText.body(12, color: widget.live ? Kanagawa.carpYellow : color)),
                      if (q.subquests != null)
                        GestureDetector(
                          onTap: () => setState(() => _open = !_open),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_open ? '▾ esconder subquests' : '▸ subquests: aulas dos cursos',
                                style: PixelText.display(6, color: Kanagawa.springBlue)),
                          ),
                        ),
                    ]),
                  ),
                ),
                Text('+${q.xp}XP\n+${q.coins}¢',
                    textAlign: TextAlign.right, style: PixelText.display(7, color: Kanagawa.springBlue)),
              ]),
            ),
          ),
        ),
      ),
      if (_open && q.subquests != null) _Subquests(kind: q.subquests!),
    ]);
  }
}

class _Subquests extends ConsumerWidget {
  const _Subquests({required this.kind});
  final SubquestKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final list = kind == SubquestKind.selfHosted
        ? courseCatalog.where((c) => c.id == 'self')
        : courseCatalog;
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 2),
      padding: const EdgeInsets.all(10),
      color: Kanagawa.sumiInk0,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SUBQUESTS · +$lessonXp XP E +$lessonCoins¢ POR AULA',
            style: PixelText.display(6, color: Kanagawa.springViolet1)),
        const SizedBox(height: 8),
        for (final c in list) CourseRow(course: c, progress: state.course(c.id)),
      ]),
    );
  }
}
