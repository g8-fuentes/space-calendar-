import 'package:flutter/material.dart';

/// Desenha uma arte de pixel com coordenadas lógicas [logicalSize]
/// escalada para o tamanho do widget.
class PixelCanvas extends StatelessWidget {
  const PixelCanvas({
    super.key,
    required this.logicalSize,
    required this.size,
    required this.paint,
  });

  final Size logicalSize;
  final Size size;
  final void Function(Canvas canvas) paint;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: size,
        child: CustomPaint(painter: _Painter(logicalSize, paint)),
      );
}

class _Painter extends CustomPainter {
  _Painter(this.logical, this.draw);
  final Size logical;
  final void Function(Canvas canvas) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / logical.width, size.height / logical.height);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
