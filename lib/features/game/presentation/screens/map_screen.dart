import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/places.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Abre o mapa da jornada numa tela própria (sem aba no menu).
void openMap(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          backgroundColor: Kanagawa.sumiInk0,
          foregroundColor: Kanagawa.fujiWhite,
          title: Text('MAPA DA JORNADA', style: PixelText.display(10)),
        ),
        body: const MapScreen(),
      ),
    ));

/// Mapa da jornada da profissão, uma semana por destino, sem fim. Todos os
/// destinos aparecem com nome e curiosidade; os que ainda não chegaram
/// ficam apagados.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    final pro = t.profession;
    final last = math.max(namedPlacesOf(pro) - 1, t.placeIndex + 3);
    final children = <Widget>[];
    int? stage;
    for (var i = 0; i <= last; i++) {
      final p = placeAt(i, pro);
      if (p.stage != stage) {
        stage = p.stage;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
          child: Text(p.region.toUpperCase(), style: PixelText.display(11, color: Kanagawa.carpYellow)),
        ));
      }
      children
        ..add(_PlaceTile(
            place: p,
            reached: i <= t.placeIndex,
            current: i == t.placeIndex,
            next: i == t.placeIndex + 1,
            missing: t.missing,
            travel: pro.travel))
        ..add(const SizedBox(height: 8));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PixelPanel(
            child: Text(
              pro.space
                  ? 'Cada semana o astronauta explora um destino. Cumpra metade das missões da semana para explorar e, '
                      'na segunda-feira, a nave parte para o próximo: primeiro a Lua e os planetas, depois as estrelas '
                      'vizinhas e, por fim, nebulosas e galáxias, sem fim.'
                  : 'Jornada de ${pro.name}: cada semana você visita um destino. Cumpra metade das missões da semana '
                      'e, na segunda-feira, você parte para o próximo: ${[
                      for (final s in pro.stages) s.$1.toLowerCase()
                    ].join(', ')} e depois o mundo todo, sem fim.',
              style: PixelText.body(14, color: Kanagawa.springViolet1),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.reached,
    required this.current,
    required this.next,
    required this.missing,
    required this.travel,
  });
  final Place place;
  final bool reached, current, next;
  final int missing;
  final String travel;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: current ? Kanagawa.waveBlue1 : Kanagawa.sumiInk4,
        border: Border.all(color: current ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
      ),
      child: Row(children: [
        SizedBox(width: 84, height: 56, child: PlaceThumb(place, locked: !reached)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SEMANA ${place.week}', style: PixelText.display(6, color: Kanagawa.springBlue)),
            const SizedBox(height: 2),
            Text(place.name.toUpperCase(),
                style: PixelText.display(8, color: reached ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            const SizedBox(height: 4),
            Text(place.fact, style: PixelText.body(13, color: Kanagawa.springViolet1)),
            if (current) Text('explorando nesta semana', style: PixelText.body(13, color: Kanagawa.carpYellow)),
            if (next)
              Text(
                  missing == 0
                      ? 'Explorado! Na segunda-feira $travel para cá.'
                      : 'Próximo destino: faltam $missing ${missing == 1 ? 'missão' : 'missões'} nesta semana.',
                  style: PixelText.body(13, color: Kanagawa.carpYellow)),
            if (!reached && !next)
              Text('🔒 ainda não chegou aqui', style: PixelText.body(13, color: Kanagawa.fujiGray)),
          ]),
        ),
      ]),
    );
    return reached || next ? tile : Opacity(opacity: .55, child: tile);
  }
}
