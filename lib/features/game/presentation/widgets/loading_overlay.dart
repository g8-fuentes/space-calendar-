import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../art/pixel_art.dart';
import 'pixel_widgets.dart';

const _steps = [
  'Lendo o arquivo...',
  'Encontrando os eventos...',
  'Transformando eventos em missões...',
  'Preparando o caminho...',
  'Abrindo as portas da jornada...',
];

/// Tela de carregamento com a pomba subindo. Fecha sozinha.
Future<void> runLoading(BuildContext context, String title, Duration duration) {
  Sfx.launch.play();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Kanagawa.sumiInk0,
    pageBuilder: (ctx, _, __) => _Loading(title: title, duration: duration),
  );
}

class _Loading extends StatefulWidget {
  const _Loading({required this.title, required this.duration});
  final String title;
  final Duration duration;

  @override
  State<_Loading> createState() => _LoadingState();
}

class _LoadingState extends State<_Loading> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _p = 0;
  int _tick = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      if (!mounted) return;
      setState(() {
        _p = (e.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0);
        _tick = e.inMilliseconds ~/ 60;
      });
      if (_p >= 1 && !_closed) {
        _closed = true;
        _ticker.stop();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Kanagawa.sumiInk0,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 320,
                  child: AspectRatio(aspectRatio: 160 / 90, child: CustomPaint(painter: _LaunchPainter(_p, _tick))),
                ),
                const SizedBox(height: 18),
                Text(widget.title,
                    textAlign: TextAlign.center, style: PixelText.display(11, color: Kanagawa.carpYellow)),
                const SizedBox(height: 16),
                PixelBar(value: _p, height: 14),
                const SizedBox(height: 10),
                Text(_steps[(_p * _steps.length).floor().clamp(0, _steps.length - 1)],
                    style: PixelText.body(15, color: Kanagawa.springViolet1)),
              ]),
            ),
          ),
        ),
      );
}

class _LaunchPainter extends CustomPainter {
  _LaunchPainter(this.p, this.tick);
  final double p;
  final int tick;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 90);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 160, 90));
    paintAscend(canvas, p, tick);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaunchPainter old) => old.p != p || old.tick != tick;
}
