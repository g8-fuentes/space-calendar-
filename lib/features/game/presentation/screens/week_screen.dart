import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';

String fmtWeek(String k) {
  final a = dateOf(k, 0), b = dateOf(k, 6);
  return '${two(a.day)}/${two(a.month)} a ${two(b.day)}/${two(b.month)}';
}

/// Resumo da semana atual, dia a dia, e o histórico das semanas.
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final k = weekKeyOf(now);
    final st = weekStatsOf(s, k);
    final w = s.weeks[k] ?? WeekRecord();
    final history = s.weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ESTA SEMANA · ${fmtWeek(k)}', style: PixelText.display(9)),
          const SizedBox(height: 4),
          Text('${st.done}/${st.total} missões · ${(st.ratio * 100).round()}%',
              style: PixelText.body(15, color: Kanagawa.springViolet1)),
          const SizedBox(height: 8),
          PixelBar(value: st.ratio, color: Kanagawa.springGreen, height: 14),
          const SizedBox(height: 14),
          for (var d = 0; d < 7; d++) ...[
            () {
              final total = daySlots(s, d).length, done = dayDone(s, w, d);
              return Row(children: [
                SizedBox(
                  width: 44,
                  child: Text(dayAbbr[d],
                      style: PixelText.display(7, color: d == dayIndexOf(now) ? Kanagawa.carpYellow : Kanagawa.fujiWhite)),
                ),
                Expanded(child: PixelBar(value: total == 0 ? 0 : done / total, color: Kanagawa.springBlue, height: 12)),
                SizedBox(
                  width: 54,
                  child: Text(total == 0 ? 'livre' : '$done/$total',
                      textAlign: TextAlign.right, style: PixelText.body(14, color: Kanagawa.springViolet1)),
                ),
              ]);
            }(),
            const SizedBox(height: 6),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('HISTÓRICO', style: PixelText.display(10)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Text('As semanas aparecem aqui conforme você marca as missões.',
                style: PixelText.body(15, color: Kanagawa.springViolet1))
          else
            for (final h in history)
              () {
                final ws = weekStatsOf(s, h);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: Text(fmtWeek(h), style: PixelText.body(15))),
                    Text('${ws.done} missões', style: PixelText.body(15, color: Kanagawa.springViolet1)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text('${(ws.ratio * 100).round()}%',
                          textAlign: TextAlign.right, style: PixelText.body(15, color: Kanagawa.carpYellow)),
                    ),
                  ]),
                );
              }(),
        ]),
      ),
    ]);
  }
}
