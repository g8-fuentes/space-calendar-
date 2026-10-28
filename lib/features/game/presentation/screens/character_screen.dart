import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/transformations.dart';
import '../controllers/game_providers.dart';
import '../widgets/character_view.dart';
import '../widgets/pixel_widgets.dart';

/// Personagem: a transformação atual, os pontos de cada atributo e quanto
/// falta para a próxima forma.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    final name = ref.watch(gameControllerProvider.select((s) => s.name));
    final form = t.form, next = t.nextForm;
    final top = math.max(1, t.attributes.values.fold(0, math.max));
    final last = math.max(namedTransformations - 1, t.formIndex + 2);
    return ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 32), children: [
      PixelPanel(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CharacterView(form: form),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text((name.isEmpty ? 'Personagem' : name).toUpperCase(),
                  style: PixelText.body(14, color: Kanagawa.springViolet1)),
              Text(form.title.toUpperCase(), style: PixelText.display(13, color: Kanagawa.carpYellow)),
              const SizedBox(height: 4),
              Text(form.description, style: PixelText.body(15)),
              const SizedBox(height: 8),
              _QuoteText(form.quote, size: 15),
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
              Text('Faltam ${t.powerMissing} ${t.powerMissing == 1 ? 'ponto' : 'pontos'} (${t.power}/${next.power})',
                  style: PixelText.body(14, color: Kanagawa.carpYellow)),
              const SizedBox(height: 8),
              Text(
                'A cada nível o dev ganha roupa, cabelo e aura novos e uma frase de dev ou de explorador '
                'do espaço. Os níveis não têm fim.',
                style: PixelText.body(13, color: Kanagawa.springViolet1),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ATRIBUTOS', style: PixelText.display(10)),
          const SizedBox(height: 4),
          Text(
              'Só aparecem os atributos das suas missões. Cada missão concluída dá pontos ao atributo da categoria dela: '
              '1 ponto a cada 10 minutos, de 3 a 24.',
              style: PixelText.body(13, color: Kanagawa.springViolet1)),
          const SizedBox(height: 12),
          if (t.shown.isEmpty)
            Text('Sincronize a agenda: os atributos aparecem conforme as categorias das suas missões.',
                style: PixelText.body(14))
          else
            for (final c in t.shown) ...[
              _AttributeRow(category: c, points: t.attributes[c.key] ?? 0, top: top),
              const SizedBox(height: 8),
            ],
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('NÍVEIS DE DEV', style: PixelText.display(10)),
          const SizedBox(height: 10),
          for (var i = 0; i <= last; i++) ...[
            _FormTile(
              form: transformationAt(i),
              reached: i <= t.formIndex,
              current: i == t.formIndex,
              next: i == t.formIndex + 1,
              missing: t.powerMissing,
            ),
            const SizedBox(height: 8),
          ],
        ]),
      ),
    ]);
  }
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

class _FormTile extends StatelessWidget {
  const _FormTile({
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
    final known = reached || next;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: current ? Kanagawa.waveBlue1 : Kanagawa.sumiInk5,
        border: Border.all(color: current ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
      ),
      child: Row(children: [
        SizedBox(width: 72, child: CharacterView(form: form, locked: !reached)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(known ? form.title.toUpperCase() : 'NÍVEL ${form.level} · ???',
                style: PixelText.display(8, color: reached ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            const SizedBox(height: 4),
            Text(
              reached
                  ? form.description
                  : next
                      ? 'Faltam $missing ${missing == 1 ? 'ponto' : 'pontos'}.'
                      : 'Libera com ${form.power} pontos.',
              style: PixelText.body(13, color: Kanagawa.springViolet1),
            ),
            if (reached) ...[
              const SizedBox(height: 4),
              _QuoteText(form.quote, size: 13),
            ],
            if (current) Text('nível atual', style: PixelText.body(13, color: Kanagawa.carpYellow)),
            if (reached && !current) Text('✓ liberado', style: PixelText.body(13, color: Kanagawa.springGreen)),
          ]),
        ),
      ]),
    );
  }
}

/// Frase do nível, com o autor embaixo.
class _QuoteText extends StatelessWidget {
  const _QuoteText(this.quote, {required this.size});
  final Quote quote;
  final double size;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: '"${quote.text}"\n', style: PixelText.body(size, color: Kanagawa.fujiWhite)),
          TextSpan(text: '— ${quote.author}', style: PixelText.body(size - 2, color: Kanagawa.springBlue)),
        ]),
      );
}
