import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/transformations.dart';
import '../controllers/game_providers.dart';
import 'character_view.dart';

/// Lista das profissões, cada uma com o personagem no nível atual. Trocar
/// de profissão muda o personagem, os nomes dos níveis e o mapa, mas os
/// pontos e as semanas exploradas continuam.
class ProfessionPicker extends ConsumerWidget {
  const ProfessionPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(gameControllerProvider.select((s) => s.profession));
    final level = ref.watch(statsProvider.select((t) => t.formIndex));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final p in professions) ...[
        _ProfessionTile(profession: p, level: level, selected: p.key == current),
        const SizedBox(height: 6),
      ],
    ]);
  }
}

class _ProfessionTile extends ConsumerWidget {
  const _ProfessionTile({required this.profession, required this.level, required this.selected});
  final Profession profession;
  final int level;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = transformationAt(level, profession);
    return Semantics(
      button: true,
      selected: selected,
      label: profession.name,
      excludeSemantics: true,
      child: Material(
        color: selected ? Kanagawa.waveBlue1 : Kanagawa.sumiInk5,
        child: InkWell(
          onTap: () {
            if (selected) return;
            Sfx.click.play();
            ref.read(gameControllerProvider.notifier).apply((g) => g.profession = profession.key);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
            ),
            child: Row(children: [
              SizedBox(width: 56, child: CharacterView(form: form)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${profession.emoji} ${profession.name.toUpperCase()}',
                      style: PixelText.display(8, color: selected ? Kanagawa.carpYellow : Kanagawa.fujiWhite)),
                  const SizedBox(height: 2),
                  Text(profession.pitch, style: PixelText.body(13, color: Kanagawa.springViolet1)),
                  Text('Nível ${form.level}: ${form.name}', style: PixelText.body(13, color: Kanagawa.springBlue)),
                ]),
              ),
              if (selected) const Icon(Icons.check, color: Kanagawa.carpYellow),
            ]),
          ),
        ),
      ),
    );
  }
}
