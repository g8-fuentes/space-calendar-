import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../controllers/game_providers.dart';
import 'event_presenter.dart';
import 'pixel_widgets.dart';

/// Linha de um curso com barra de progresso e botões de aula.
class CourseRow extends ConsumerWidget {
  const CourseRow({super.key, required this.course, required this.progress});
  final Course course;
  final CourseProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(course.color);
    final done = progress.done;
    final total = progress.total;
    final completed = progress.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${course.name}${completed ? ' · concluído' : ''}',
                style: PixelText.body(14, color: completed ? Kanagawa.carpYellow : Kanagawa.fujiWhite)),
          ),
          Text('$done/$total', style: PixelText.body(13, color: Kanagawa.springViolet1)),
          const SizedBox(width: 8),
          PixelButton(
            label: '−',
            dense: true,
            color: Kanagawa.sumiInk5,
            textColor: Kanagawa.fujiWhite,
            onPressed: done == 0 ? null : () => ref.read(gameControllerProvider.notifier).removeLesson(course.id),
          ),
          const SizedBox(width: 6),
          PixelButton(
            label: '+1 aula',
            dense: true,
            onPressed: completed
                ? null
                : () async {
                    final events = ref.read(gameControllerProvider.notifier).addLesson(course.id);
                    showGameToast(context, '+1 aula de ${course.name}');
                    await presentEvents(context, events);
                  },
          ),
        ]),
        const SizedBox(height: 4),
        PixelBar(value: total == 0 ? 0 : done / total, color: color, height: 8),
      ]),
    );
  }
}
