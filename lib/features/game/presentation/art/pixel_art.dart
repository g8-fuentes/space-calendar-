import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
export 'holy_art.dart';

/// Grade de pixels: null = transparente.
typedef PixelGrid = List<List<Color?>>;

const _ink = Kanagawa.sumiInk0;

PixelGrid outlined(PixelGrid g) {
  final h = g.length, w = g.first.length;
  final out = [for (final row in g) List<Color?>.of(row)];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (g[y][x] != null) continue;
      final near = (y > 0 && g[y - 1][x] != null) ||
          (y < h - 1 && g[y + 1][x] != null) ||
          (x > 0 && g[y][x - 1] != null) ||
          (x < w - 1 && g[y][x + 1] != null);
      if (near) out[y][x] = _ink;
    }
  }
  return out;
}

void paintGrid(Canvas canvas, PixelGrid g, Offset origin, double scale) {
  final paint = Paint();
  for (var j = 0; j < g.length; j++) {
    for (var i = 0; i < g[j].length; i++) {
      final c = g[j][i];
      if (c == null) continue;
      paint.color = c;
      canvas.drawRect(Rect.fromLTWH(origin.dx + i * scale, origin.dy + j * scale, scale + 0.3, scale + 0.3), paint);
    }
  }
}
