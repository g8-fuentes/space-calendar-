import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/destinations.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_canvas.dart';
import '../widgets/pixel_widgets.dart';

/// Mapa estelar: destinos visitados, o atual e os próximos.
/// A lista é gerada sob demanda, então não tem fim.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final cur = stats.destinationIndex;
    final here = stats.destination;
    final next = stats.nextDestination;
    final ratio = (stats.xp - here.xpRequired) / (next.xpRequired - here.xpRequired);
    final visible = cur + 6;

    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: PixelPanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionTitle('Mapa estelar · destino ${cur + 1}', color: Kanagawa.carpYellow),
                const SizedBox(height: 8),
                Text(
                  'Você está em ${here.name}. Faltam ${next.xpRequired - stats.xp} XP para chegar a ${next.name}. '
                  'Depois de Proxima Centauri, novos mundos são descobertos sem fim.',
                  style: PixelText.body(15),
                ),
                const SizedBox(height: 10),
                PixelBar(value: ratio, height: 16, color: Kanagawa.carpYellow),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.builder(
            itemCount: visible + 1,
            itemBuilder: (context, i) {
              final index = visible - i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DestinationTile(d: destinationAt(index), current: cur),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.d, required this.current});
  final Destination d;
  final int current;

  @override
  Widget build(BuildContext context) {
    final i = d.index;
    final status = i < current
        ? 'visitado'
        : i == current
            ? 'você está aqui'
            : i == current + 1
                ? 'próximo destino'
                : 'bloqueado';
    final locked = i > current + 1;
    return Opacity(
      opacity: locked ? .5 : 1,
      child: PixelPanel(
        borderColor: i == current ? Kanagawa.carpYellow : Kanagawa.sumiInk0,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PixelCanvas(
            logicalSize: const Size(40, 40),
            size: const Size(60, 60),
            paint: (c) => paintBody(c, d, const Offset(20, 20), 12, 0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name.toUpperCase(), style: PixelText.display(9)),
              const SizedBox(height: 4),
              Text('$status · ${d.xpRequired} XP', style: PixelText.body(13, color: Kanagawa.springViolet1)),
              if (i <= current) ...[
                const SizedBox(height: 4),
                Text(d.fact, style: PixelText.body(14)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
