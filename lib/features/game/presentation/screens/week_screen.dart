import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';

String fmtWeek(String k) {
  final a = dateOf(k, 0), b = dateOf(k, 6);
  return '${two(a.day)}/${two(a.month)} a ${two(b.day)}/${two(b.month)}';
}

/// Baú semanal e histórico das semanas e compras.
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, String key) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final chest = ctrl.apply((s) => GameRules.openChest(s, key, ctrl.now));
    if (chest == null) return;
    ctrl.celebrate(chest.xp);
    final item = chest.item == null ? null : shopItem(chest.item!)?.name;
    ctrl.notify([
      Notice('BAÚ ${tierByKey(chest.tier).name.toUpperCase()}',
          '+${chest.coins} moedas e +${chest.xp} XP${item != null ? '. Item novo: $item.' : '.'}',
          sound: 'chest'),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final k = weekKeyOf(now);
    final st = weekStatsOf(s, k);
    final tier = tierFor(st.ratio);
    final chest = s.weeks[k]?.chest;
    final pending = s.weeks.keys
        .where((x) => x.compareTo(k) < 0 && s.weeks[x]!.chest == null && tierFor(weekStatsOf(s, x).ratio) != null)
        .toList()
      ..sort();
    final history = s.weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('BAÚ DA SEMANA · ${fmtWeek(k)}', style: PixelText.display(10).copyWith(height: 1.6)),
          const SizedBox(height: 4),
          Text('${st.done}/${st.total} missões · ${(st.ratio * 100).round()}%', style: PixelText.body(15, color: Kanagawa.springViolet1)),
          const SizedBox(height: 8),
          PixelBar(value: st.ratio, color: Kanagawa.carpYellow, height: 14),
          const SizedBox(height: 12),
          for (final x in chestTiers) ...[
            _TierBox(tier: x, hit: st.ratio >= x.min - 1e-9),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          if (chest != null)
            Text('Baú desta semana já aberto: ${tierByKey(chest.tier).name}.', style: PixelText.body(15, color: Kanagawa.springViolet1))
          else if (st.ratio >= 1)
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(label: 'Abrir baú de ouro agora', sound: false, onPressed: () => _open(context, ref, k)),
            )
          else
            Text(
              tier != null
                  ? 'Baú ${tier.name} garantido. Ele abre na segunda-feira, ou agora se você chegar a 100%.'
                  : 'Complete 60% das missões da semana para ganhar o baú de bronze.',
              style: PixelText.body(15, color: Kanagawa.springViolet1),
            ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('BAÚS ESPERANDO', style: PixelText.display(9)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final x in pending)
                PixelButton(
                  label: 'Abrir ${tierFor(weekStatsOf(s, x).ratio)!.name} · ${fmtWeek(x)}',
                  dense: true,
                  sound: false,
                  onPressed: () => _open(context, ref, x),
                ),
            ]),
          ],
          const SizedBox(height: 14),
          Text(
            'Cada dia com menos da metade das missões feitas custa $weakDayPenalty moedas.'
            '${t.weakDays > 0 ? ' Dias fracos até agora: ${t.weakDays}${s.shields > 0 ? ', escudos usados: ${s.shields < t.weakDays ? s.shields : t.weakDays}' : ''}.' : ' Nenhum dia fraco até agora.'}',
            style: PixelText.body(14, color: Kanagawa.springViolet1),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('HISTÓRICO', style: PixelText.display(11)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Text('As semanas aparecem aqui conforme você joga.', style: PixelText.body(15, color: Kanagawa.springViolet1))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: PixelText.display(7, color: Kanagawa.springViolet1),
                dataTextStyle: PixelText.body(15),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('SEMANA')),
                  DataColumn(label: Text('MISSÕES')),
                  DataColumn(label: Text('%')),
                  DataColumn(label: Text('XP')),
                  DataColumn(label: Text('BAÚ')),
                ],
                rows: [
                  for (final h in history)
                    () {
                      final ws = weekStatsOf(s, h);
                      final c = s.weeks[h]!.chest;
                      return DataRow(cells: [
                        DataCell(Text(fmtWeek(h))),
                        DataCell(Text('${ws.done}/${ws.total}')),
                        DataCell(Text('${(ws.ratio * 100).round()}%')),
                        DataCell(Text('${ws.xp}')),
                        DataCell(Text(c == null ? '—' : tierByKey(c.tier).name)),
                      ]);
                    }(),
                ],
              ),
            ),
          if (s.purchases.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('COMPRAS', style: PixelText.display(9)),
            const SizedBox(height: 8),
            for (final p in s.purchases.reversed.take(30))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(p.name, style: PixelText.body(15))),
                  Text('${p.price}', style: PixelText.body(15, color: Kanagawa.carpYellow)),
                  const SizedBox(width: 12),
                  () {
                    final d = DateTime.fromMillisecondsSinceEpoch(p.at);
                    return Text('${two(d.day)}/${two(d.month)}', style: PixelText.body(15, color: Kanagawa.springViolet1));
                  }(),
                ]),
              ),
          ],
        ]),
      ),
    ]);
  }
}

class _TierBox extends StatelessWidget {
  const _TierBox({required this.tier, required this.hit});
  final ChestTier tier;
  final bool hit;

  @override
  Widget build(BuildContext context) {
    final c = Color(tier.color);
    final fg = hit ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: hit ? c : Kanagawa.sumiInk5, border: Border.all(color: c, width: 3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tier.name.toUpperCase(), style: PixelText.display(9, color: fg)),
        const SizedBox(height: 4),
        Text(tier.description, style: PixelText.body(14, color: hit ? fg : Kanagawa.springViolet1)),
        Text('+${tier.coins} moedas · +${tier.xp} XP', style: PixelText.body(14, color: hit ? fg : Kanagawa.springViolet1)),
      ]),
    );
  }
}
