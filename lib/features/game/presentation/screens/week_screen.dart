import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/schedule.dart';
import '../../domain/services/game_stats.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import '../widgets/event_presenter.dart';
import '../widgets/pixel_canvas.dart';
import '../widgets/pixel_widgets.dart';

class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final state = ref.watch(gameControllerProvider);
    final key = weekKeyOf(now);
    final ws = weekStatsOf(state, key);
    final tier = tierFor(ws.ratio);
    final boss = bossForWeek(key, weekMaxXp);
    final hpLeft = math.max(0, boss.hp - ws.xp);
    final weak = weakDaysOf(state, key, now);
    final chest = state.week(key).chest;
    final monday = DateTime.parse(key);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final pending = state.weeks.keys
        .where((k) => k.compareTo(key) < 0 && state.weeks[k]!.chest == null && tierFor(weekStatsOf(state, k).ratio) != null)
        .toList()
      ..sort();

    Future<void> open(String k) async {
      final events = ref.read(gameControllerProvider.notifier).openChest(k);
      await presentEvents(context, events);
    }

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        SectionTitle('Semana ${_dm(monday)} a ${_dm(sunday)}', color: Kanagawa.fujiWhite),
        const SizedBox(height: 14),
        PixelPanel(
          accent: Color(boss.color),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PixelCanvas(
              logicalSize: const Size(40, 40),
              size: const Size(96, 96),
              paint: (c) => paintBoss(c, Color(boss.color), hpLeft == 0),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DUELO DE DOMINGO', style: PixelText.display(8, color: Kanagawa.springViolet1)),
                const SizedBox(height: 4),
                Text(boss.name.toUpperCase(), style: PixelText.display(9, color: Color(boss.color))),
                const SizedBox(height: 6),
                Text(
                  hpLeft == 0
                      ? 'Derrotado! O bônus de +$bossBonusCoins moedas e +$bossBonusXp XP entra no baú.'
                      : 'Cada XP de missão é um disparo do laser. Vida: $hpLeft de ${boss.hp}.',
                  style: PixelText.body(14),
                ),
                const SizedBox(height: 8),
                PixelBar(value: hpLeft / boss.hp, color: Kanagawa.autumnRed),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        PixelPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${ws.done} de ${allQuests.length} missões (${(ws.ratio * 100).round()}%) · ${ws.xp} de $weekMaxXp XP',
                style: PixelText.body(15)),
            const SizedBox(height: 8),
            PixelBar(value: ws.ratio, height: 18, color: tier == null ? Kanagawa.springBlue : Color(tier.color)),
            const SizedBox(height: 8),
            Text(
              weak.isEmpty
                  ? 'Nenhum dia fraco até agora.'
                  : 'Dias fracos (menos de 50%): ${weak.join(', ')}. Cada um custa $weakDayPenalty moedas.',
              style: PixelText.body(13, color: Kanagawa.springViolet1),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth < 420 ? 1 : 3;
              return Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in chestTiers)
                  SizedBox(
                    width: (c.maxWidth - 8 * (cols - 1)) / cols,
                    child: _TierCard(tier: t, reached: ws.ratio >= t.minRatio - 1e-9),
                  ),
              ]);
            }),
          ]),
        ),
        const SizedBox(height: 14),
        PixelPanel(
          child: Row(children: [
            PixelCanvas(
              logicalSize: const Size(32, 32),
              size: const Size(72, 72),
              paint: (c) => paintChest(c, tier == null ? Kanagawa.sumiInk6 : Color(tier.color), chest != null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: chest != null
                  ? Text(
                      'Baú ${tierByKey(chest.tier).name} aberto: +${chest.coins} moedas e +${chest.xp} XP'
                      '${chest.item == null ? '.' : ', ${cosmeticById(chest.item!)?.name}.'}',
                      style: PixelText.body(15))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('O baú abre com 100% das missões ou depois que a semana termina, no nível alcançado.',
                          style: PixelText.body(14)),
                      const SizedBox(height: 8),
                      PixelButton(
                        label: ws.ratio >= 1 ? 'Abrir baú de ouro' : 'Baú fechado',
                        onPressed: ws.ratio >= 1 ? () => open(key) : null,
                      ),
                    ]),
            ),
          ]),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionTitle('Baús pendentes'),
          const SizedBox(height: 8),
          for (final k in pending.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PixelPanel(
                child: Row(children: [
                  Expanded(
                    child: Text(
                      'Semana de ${_dm(DateTime.parse(k))} · ${(weekStatsOf(state, k).ratio * 100).round()}% · '
                      '${tierFor(weekStatsOf(state, k).ratio)!.name}',
                      style: PixelText.body(15),
                    ),
                  ),
                  PixelButton(label: 'Abrir', onPressed: () => open(k)),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  static String _dm(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.reached});
  final ChestTier tier;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final c = Color(tier.color);
    final fg = reached ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: reached ? c : Kanagawa.sumiInk5, border: Border.all(color: c, width: 3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tier.name.toUpperCase(), style: PixelText.display(8, color: fg)),
        const SizedBox(height: 4),
        Text(tier.description, style: PixelText.body(13, color: fg)),
        Text('+${tier.coins} moedas · +${tier.xp} XP', style: PixelText.body(13, color: fg)),
      ]),
    );
  }
}
