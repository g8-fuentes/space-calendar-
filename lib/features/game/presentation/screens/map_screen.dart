import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/places.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Mapa da jornada, uma semana por destino: Sistema Solar, estrelas
/// vizinhas e a galáxia, sem fim. Os destinos visitados mostram nome e
/// curiosidade; o próximo mostra o nome; o resto fica em segredo.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    final last = math.max(namedPlaces - 1, t.placeIndex + 3);
    final children = <Widget>[];
    Region? region;
    for (var i = 0; i <= last; i++) {
      final p = placeAt(i);
      if (p.region != region) {
        region = p.region;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
          child: Text(regionName(region).toUpperCase(), style: PixelText.display(11, color: Kanagawa.carpYellow)),
        ));
      }
      children
        ..add(_PlaceTile(
            place: p,
            reached: i <= t.placeIndex,
            current: i == t.placeIndex,
            next: i == t.placeIndex + 1,
            missing: t.missing))
        ..add(const SizedBox(height: 8));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PixelPanel(
            child: Text(
              'Cada semana o dev explora um destino. Cumpra metade das missões da semana para explorar e, na '
              'segunda-feira, a nave parte para o próximo: primeiro a Lua e os planetas, depois as estrelas '
              'vizinhas e, por fim, nebulosas e galáxias, sem fim.',
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
  const _PlaceTile(
      {required this.place, required this.reached, required this.current, required this.next, required this.missing});
  final Place place;
  final bool reached, current, next;
  final int missing;

  @override
  Widget build(BuildContext context) {
    final known = reached || next;
    return Container(
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
            Text(known ? place.name.toUpperCase() : '???',
                style: PixelText.display(8, color: reached ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            const SizedBox(height: 4),
            Text(
              reached
                  ? place.fact
                  : next
                      ? (missing == 0
                          ? 'Explorado! A nave parte para cá na segunda-feira.'
                          : 'Próximo destino: faltam $missing ${missing == 1 ? 'missão' : 'missões'} nesta semana.')
                      : 'Ainda não descoberto.',
              style: PixelText.body(13, color: Kanagawa.springViolet1),
            ),
            if (current) Text('explorando nesta semana', style: PixelText.body(13, color: Kanagawa.carpYellow)),
          ]),
        ),
      ]),
    );
  }
}
