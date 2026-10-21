import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/catalog.dart';
import '../controllers/game_providers.dart';
import 'pixel_widgets.dart';

/// Cabeçalho: nível, nome, rank, XP, poderes ativos, moedas e som.
class Hud extends ConsumerWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final rc = Color(t.rank.color);
    final shieldsLeft = s.shields - t.weakDays;
    final boosts = [
      if (s.boostCharges > 0) ('XP +50% ×${s.boostCharges}', Kanagawa.springBlue),
      if (s.magnetCharges > 0) ('MOEDAS ×2 ×${s.magnetCharges}', Kanagawa.carpYellow),
      if (shieldsLeft > 0) ('ESCUDO ×$shieldsLeft', Kanagawa.springGreen),
    ];
    return PixelPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: rc, border: Border.all(color: Kanagawa.sumiInk0, width: 3)),
            child: Column(children: [
              Text('LV', style: PixelText.display(7, color: Kanagawa.sumiInk0)),
              Text('${t.lv}', style: PixelText.display(12, color: Kanagawa.sumiInk0)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((s.name.isEmpty ? 'Astronauta' : s.name).toUpperCase(),
                  style: PixelText.display(10), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${t.rank.name}${s.suitMode > 0 ? ' · ${suitModes[s.suitMode].name}' : ''}',
                  style: PixelText.body(14, color: rc), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CoinPrice(t.coins),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              toggled: s.sound,
              child: InkWell(
                onTap: () {
                  final ctrl = ref.read(gameControllerProvider.notifier);
                  ctrl.apply((g) => g.sound = !g.sound);
                  if (ref.read(gameControllerProvider).sound) Sfx.save.play();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Kanagawa.sumiInk5,
                  child: Text('SOM: ${s.sound ? 'ON' : 'OFF'}', style: PixelText.display(7)),
                ),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 10),
        PixelBar(value: t.level.ratio),
        const SizedBox(height: 4),
        Text('${t.level.into} / ${t.level.need} XP · total ${t.xp}', style: PixelText.body(13, color: Kanagawa.springViolet1)),
        if (boosts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (label, color) in boosts)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                color: color,
                child: Text(label, style: PixelText.display(6, color: Kanagawa.sumiInk0)),
              ),
          ]),
        ],
      ]),
    );
  }
}
