import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../controllers/game_providers.dart';
import 'pixel_widgets.dart';

/// Cabeçalho com nível, rank, XP e moedas. Toque abre o perfil.
class Hud extends ConsumerWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final mode = ref.watch(gameControllerProvider.select((s) => s.suitMode));
    final rankColor = Color(stats.rank.color);
    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: InkWell(
        onTap: () => context.push('/perfil'),
        child: PixelPanel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(color: rankColor, border: Border.all(color: Kanagawa.sumiInk0, width: 3)),
                child: Column(children: [
                  Text('LV', style: PixelText.display(7, color: Kanagawa.sumiInk0)),
                  Text('${stats.lv}', style: PixelText.display(12, color: Kanagawa.sumiInk0)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GUILHERME FUENTES', style: PixelText.display(10)),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.rank.name} · Traje Mk ${stats.suitMk}${mode > 0 ? ' · ${suitModes[mode].name}' : ''}',
                    style: PixelText.body(14, color: rankColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              CoinPrice(stats.coins),
            ]),
            const SizedBox(height: 10),
            PixelBar(value: stats.level.ratio),
            const SizedBox(height: 4),
            Text('${stats.level.intoLevel} / ${stats.level.needed} XP · total ${stats.xp}',
                style: PixelText.body(13, color: Kanagawa.springViolet1)),
          ]),
        ),
      ),
    );
  }
}
