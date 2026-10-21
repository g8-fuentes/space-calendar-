import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/course_row.dart';

/// Cursos de programação (subquests) e trilhas de idiomas.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final state = ref.watch(gameControllerProvider);
    final stats = ref.watch(statsProvider);
    final thisWeek = state.lessons.where((l) => l.weekKey == weekKeyOf(now)).length;

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionTitle('Cursos de programação', color: Kanagawa.fujiWhite),
        const SizedBox(height: 8),
        Text(
          'Cada aula vale +$lessonXp XP. Concluir um curso derrota um chefão: +$courseXp XP e +$courseCoins moedas. '
          'Aulas nesta semana: $thisWeek.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        const SizedBox(height: 12),
        for (final c in courseCatalog)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PixelPanel(
              accent: Color(c.color),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CourseRow(course: c, progress: state.course(c.id)),
                _TotalField(courseId: c.id, total: state.course(c.id).total),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        const SectionTitle('Idiomas', color: Kanagawa.fujiWhite),
        const SizedBox(height: 8),
        Text('A sequência conta dias seguidos com pelo menos uma missão do idioma.',
            style: PixelText.body(14, color: Kanagawa.springViolet1)),
        const SizedBox(height: 10),
        Row(children: [
          for (final (tag, name, color) in [
            ('es', 'Espanhol', Kanagawa.autumnRed),
            ('en', 'Inglês', Kanagawa.springBlue),
          ]) ...[
            if (tag == 'en') const SizedBox(width: 10),
            Expanded(
              child: PixelPanel(
                accent: color,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.toUpperCase(), style: PixelText.display(9)),
                  const SizedBox(height: 8),
                  Text('${languageStreak(state, tag, now)} DIAS', style: PixelText.display(14, color: color)),
                  const SizedBox(height: 6),
                  Text('Sequência atual · ${stats.tag(tag)} missões no total', style: PixelText.body(13)),
                ]),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _TotalField extends ConsumerStatefulWidget {
  const _TotalField({required this.courseId, required this.total});
  final String courseId;
  final int total;

  @override
  ConsumerState<_TotalField> createState() => _TotalFieldState();
}

class _TotalFieldState extends ConsumerState<_TotalField> {
  late final TextEditingController _ctrl = TextEditingController(text: '${widget.total}');

  @override
  void didUpdateWidget(covariant _TotalField old) {
    super.didUpdateWidget(old);
    if (old.total != widget.total && _ctrl.text != '${widget.total}') _ctrl.text = '${widget.total}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text);
    if (v == null) return;
    ref.read(gameControllerProvider.notifier).setCourseTotal(widget.courseId, v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('Total de aulas', style: PixelText.body(13, color: Kanagawa.springViolet1)),
      const SizedBox(width: 10),
      SizedBox(
        width: 80,
        child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: PixelText.body(15),
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
          onSubmitted: (_) => _commit(),
          onEditingComplete: _commit,
          onTapOutside: (_) {
            _commit();
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    ]);
  }
}
