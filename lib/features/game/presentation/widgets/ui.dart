import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/services/game_rules.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import 'pixel_widgets.dart';

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 2600)));
}

/// Mostra, um de cada vez, os avisos grandes que chegam na fila.
class NoticeListener extends ConsumerStatefulWidget {
  const NoticeListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NoticeListener> createState() => _NoticeListenerState();
}

class _NoticeListenerState extends ConsumerState<NoticeListener> {
  bool _showing = false;

  Future<void> _drain() async {
    if (_showing) return;
    _showing = true;
    while (mounted) {
      final q = ref.read(noticesProvider);
      if (q.isEmpty) break;
      final n = q.first;
      ref.read(noticesProvider.notifier).state = q.sublist(1);
      switch (n.sound) {
        case 'chest':
          Sfx.chest.play();
        case 'none':
          break;
        default:
          Sfx.level.play();
          if (n.enemyLevel != null) Future.delayed(const Duration(milliseconds: 700), Sfx.foe.play);
      }
      await showNotice(context, n);
    }
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(noticesProvider, (_, next) {
      if (next.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
    });
    return widget.child;
  }
}

Future<void> showNotice(BuildContext context, Notice n) => showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Kanagawa.sumiInk4,
        shape: const RoundedRectangleBorder(side: BorderSide(color: Kanagawa.sumiInk0, width: 4)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(n.title, textAlign: TextAlign.center, style: PixelText.display(13, color: Kanagawa.carpYellow)),
            if (n.enemyLevel != null) ...[
              const SizedBox(height: 14),
              Container(
                width: 120,
                height: 120,
                color: Kanagawa.sumiInk0,
                child: CustomPaint(painter: EnemyPainter(enemyFor(n.enemyLevel!))),
              ),
            ],
            const SizedBox(height: 14),
            Text(n.text, textAlign: TextAlign.center, style: PixelText.body(16)),
            const SizedBox(height: 16),
            PixelButton(label: 'Continuar', onPressed: () => Navigator.of(ctx).pop()),
          ]),
        ),
      ),
    );

class EnemyPainter extends CustomPainter {
  EnemyPainter(this.enemy);
  final Enemy enemy;

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.shortestSide * .86;
    paintEnemyFitted(canvas, enemy, Offset((size.width - box) / 2, (size.height - box) / 2), box);
  }

  @override
  bool shouldRepaint(covariant EnemyPainter old) => old.enemy.level != enemy.level;
}

/// Folha de formulário que sobe de baixo, no estilo pixel.
Future<T?> openSheet<T>(BuildContext context, Widget Function(BuildContext) builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Kanagawa.sumiInk4,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Kanagawa.sumiInk0, width: 4)),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: builder(ctx)),
        ),
      ),
    );

InputDecoration pixelInput(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: PixelText.body(15, color: Kanagawa.springViolet1),
      hintStyle: PixelText.body(15, color: Kanagawa.sumiInk6),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});
  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text!, style: PixelText.body(15, color: Kanagawa.sakuraPink)),
        );
}

/// Pergunta "tem certeza?" dentro da própria folha.
class ConfirmBar extends StatelessWidget {
  const ConfirmBar({super.key, required this.text, required this.onYes, required this.onNo, this.yesLabel = 'Sim'});
  final String text;
  final String yesLabel;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) => Container(
        color: Kanagawa.sumiInk0,
        padding: const EdgeInsets.all(10),
        child: Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(text, style: PixelText.body(15)),
          PixelButton(label: yesLabel, color: Kanagawa.autumnRed, textColor: Kanagawa.fujiWhite, onPressed: onYes, sound: false),
          PixelButton(label: 'Não', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: onNo),
        ]),
      );
}

/// Chip com a cor da categoria ou do curso.
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.color, this.off = false});
  final String text;
  final Color? color;
  final bool off;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Kanagawa.sumiInk0,
          border: off || color == null ? null : Border(left: BorderSide(color: color!, width: 3)),
        ),
        child: Text(text, style: PixelText.body(13, color: off ? Kanagawa.springViolet1 : Kanagawa.fujiWhite)),
      );
}

class EmptyBox extends StatelessWidget {
  const EmptyBox(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Kanagawa.sumiInk0,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: PixelText.body(16, color: Kanagawa.springViolet1)),
          const SizedBox(height: 6),
          Text(subtitle, style: PixelText.body(14, color: Kanagawa.springViolet1)),
        ]),
      );
}

/// Seletor de dias da semana (SEG ... DOM).
class DayPicker extends StatelessWidget {
  const DayPicker({super.key, required this.selected, required this.onChanged});
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              selected: selected.contains(i),
              button: true,
              label: dayNames[i],
              child: InkWell(
                onTap: () {
                  Sfx.click.play();
                  final next = Set.of(selected);
                  if (!next.remove(i)) next.add(i);
                  onChanged(next);
                },
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  color: selected.contains(i) ? Kanagawa.springBlue : Kanagawa.sumiInk0,
                  child: Text(dayAbbr[i],
                      style: PixelText.display(7, color: selected.contains(i) ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
                ),
              ),
            ),
          ),
        ],
      ]);
}
