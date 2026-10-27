import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/transformations.dart';
import '../controllers/game_providers.dart';
import '../widgets/character_view.dart';
import '../widgets/pixel_widgets.dart';

/// Personagem: o nível atual com a sua passagem da Bíblia, os pontos de
/// cada atributo e a jornada de fé, que não tem fim.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    final name = ref.watch(gameControllerProvider.select((s) => s.name));
    final form = t.form, next = t.nextForm;
    final top = math.max(1, t.attributes.values.fold(0, math.max));
    // do próximo nível ainda bloqueado até o primeiro
    final last = t.formIndex + 3;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
      itemCount: 3 + last + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return PixelPanel(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CharacterView(form: form),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text((name.isEmpty ? 'Personagem' : name).toUpperCase(),
                      style: PixelText.body(14, color: Kanagawa.springViolet1)),
                  Text(form.title.toUpperCase(), style: PixelText.display(12, color: Kanagawa.carpYellow)),
                  const SizedBox(height: 8),
                  _PassageText(form.passage, size: 16),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text('PONTOS TOTAIS', style: PixelText.display(8, color: Kanagawa.springViolet1))),
                    Text('${t.power}', style: PixelText.display(11)),
                  ]),
                  const SizedBox(height: 10),
                  Text('PRÓXIMO: ${next.title.toUpperCase()}', style: PixelText.display(8)),
                  const SizedBox(height: 6),
                  PixelBar(value: t.formProgress, color: Kanagawa.carpYellow, height: 14),
                  const SizedBox(height: 4),
                  Text(
                      'Faltam ${t.powerMissing} ${t.powerMissing == 1 ? 'ponto' : 'pontos'} (${t.power}/${next.power})',
                      style: PixelText.body(14, color: Kanagawa.carpYellow)),
                  const SizedBox(height: 8),
                  Text(
                    'A cada nível ele fica mais perto de Jesus e de Deus: a luz cresce, vem a auréola, os raios do céu '
                    'e as asas de luz. Cada nível traz uma passagem da Bíblia, e a jornada não tem fim.',
                    style: PixelText.body(13, color: Kanagawa.springViolet1),
                  ),
                ]),
              ),
            ]),
          );
        }
        if (i == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: PixelPanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('ATRIBUTOS', style: PixelText.display(10)),
                const SizedBox(height: 4),
                Text(
                    'Só aparecem os atributos das suas missões. Cada missão concluída dá pontos ao atributo da '
                    'categoria dela: 1 ponto a cada 10 minutos, de 3 a 24.',
                    style: PixelText.body(13, color: Kanagawa.springViolet1)),
                const SizedBox(height: 12),
                if (t.shown.isEmpty)
                  Text('Importe a agenda: os atributos aparecem conforme as categorias das suas missões.',
                      style: PixelText.body(14))
                else
                  for (final c in t.shown) ...[
                    _AttributeRow(category: c, points: t.attributes[c.key] ?? 0, top: top),
                    const SizedBox(height: 8),
                  ],
              ]),
            ),
          );
        }
        if (i == 2) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
            child: Text('JORNADA DE FÉ', style: PixelText.display(11, color: Kanagawa.carpYellow)),
          );
        }
        final level = last - (i - 3);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LevelTile(
            form: transformationAt(level),
            reached: level <= t.formIndex,
            current: level == t.formIndex,
            next: level == t.formIndex + 1,
            missing: t.powerMissing,
          ),
        );
      },
    );
  }
}

class _PassageText extends StatelessWidget {
  const _PassageText(this.passage, {this.size = 14});
  final Passage passage;
  final double size;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('“${passage.text}”', style: PixelText.body(size)),
        const SizedBox(height: 2),
        Text(passage.ref, style: PixelText.body(size - 2, color: Kanagawa.carpYellow)),
      ]);
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.category, required this.points, required this.top});
  final Category category;
  final int points, top;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return Semantics(
      label: '${category.name}: $points pontos',
      excludeSemantics: true,
      child: Row(children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        SizedBox(width: 104, child: Text(category.name.toUpperCase(), style: PixelText.display(7))),
        Expanded(child: PixelBar(value: points / top, color: color, height: 12)),
        SizedBox(
          width: 48,
          child: Text('$points', textAlign: TextAlign.right, style: PixelText.body(15, color: color)),
        ),
      ]),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.form,
    required this.reached,
    required this.current,
    required this.next,
    required this.missing,
  });
  final Transformation form;
  final bool reached, current, next;
  final int missing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: current ? Kanagawa.waveBlue1 : Kanagawa.sumiInk4,
        border: Border.all(color: current ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 64, child: CharacterView(form: form, locked: !reached)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reached || next ? form.title.toUpperCase() : 'NÍVEL ${form.level}',
                style: PixelText.display(8, color: reached ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            const SizedBox(height: 4),
            if (reached)
              _PassageText(form.passage, size: 13)
            else
              Text(
                next
                    ? 'Faltam $missing ${missing == 1 ? 'ponto' : 'pontos'} para a próxima passagem.'
                    : 'Libera com ${form.power} pontos.',
                style: PixelText.body(13, color: Kanagawa.springViolet1),
              ),
            if (current) Text('nível atual', style: PixelText.body(13, color: Kanagawa.carpYellow)),
          ]),
        ),
      ]),
    );
  }
}
