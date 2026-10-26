import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/places.dart';
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
            Text(n.title, textAlign: TextAlign.center, style: PixelText.display(12, color: Kanagawa.carpYellow)),
            if (n.place != null) ...[
              const SizedBox(height: 14),
              SizedBox(width: 220, height: 130, child: PlaceThumb(placeAt(n.place!))),
            ],
            const SizedBox(height: 14),
            Text(n.text, textAlign: TextAlign.center, style: PixelText.body(16)),
            const SizedBox(height: 16),
            PixelButton(label: 'Continuar', onPressed: () => Navigator.of(ctx).pop()),
          ]),
        ),
      ),
    );

/// Miniatura de um lugar da jornada.
class PlaceThumb extends StatelessWidget {
  const PlaceThumb(this.place, {super.key, this.locked = false});
  final Place place;
  final bool locked;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: locked ? .3 : 1,
        child: CustomPaint(painter: _ThumbPainter(place)),
      );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.place);
  final Place place;

  @override
  void paint(Canvas canvas, Size size) => paintPlaceThumb(canvas, place, size, 0);

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.place.index != place.index;
}

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

/// Pergunta "tem certeza?" no lugar dos botões.
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
