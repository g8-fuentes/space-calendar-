import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/places.dart';

/// Grade de pixels: null = transparente.
typedef PixelGrid = List<List<Color?>>;

const _ink = Px.sumiInk0;

/// Teal do Tokyo Night Moon (a "chuva" do terminal) e o preto do fundo.
const matrixGreen = Color(0xFF4FD6BE), matrixDark = Color(0xFF1B1D2B);

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

void _rect(Canvas canvas, Paint p, double x, double y, double w, double h, Color c) {
  p.color = c;
  canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w.roundToDouble(), h.roundToDouble()), p);
}

int _hash(int n) {
  var h = n * 2654435761 & 0xFFFFFFFF;
  h ^= h >> 15;
  h = h * 2246822519 & 0xFFFFFFFF;
  return h ^ (h >> 13);
}

/// Chuva de código da Matrix em [area]: colunas de caracteres verdes caindo,
/// com a cabeça mais clara. [density] vai de 0 a 1.
void paintRain(Canvas canvas, Rect area, int tick, {double density = .6, double cell = 5, int alpha = 255}) {
  final p = Paint();
  final cols = (area.width / cell).floor();
  final rows = (area.height / (cell + 1)).ceil() + 1;
  for (var c = 0; c < cols; c++) {
    final h = _hash(c + 17);
    if ((h % 100) / 100 > density) continue;
    final speed = .12 + (h >> 8) % 7 * .04;
    final len = 6 + (h >> 4) % 10;
    final head = ((tick * speed + (h >> 12) % 60) % (rows + len)).floor();
    for (var k = 0; k < len; k++) {
      final row = head - k;
      if (row < 0 || row >= rows) continue;
      final fade = 1 - k / len;
      final color = k == 0 ? const Color(0xFFC8D3F5) : matrixGreen;
      final a = (alpha * (k == 0 ? 1 : fade * .75)).round().clamp(0, 255);
      // um "caractere" de 3x4 pixels, trocando de vez em quando
      final glyph = _hash(c * 131 + row * 7 + (tick ~/ (12 + k)) * (k == 0 ? 1 : 0));
      final x0 = area.left + c * cell, y0 = area.top + row * (cell + 1);
      for (var b = 0; b < 12; b++) {
        if ((glyph >> b) & 1 == 0) continue;
        _rect(canvas, p, x0 + b % 3 * (cell / 4), y0 + b ~/ 3 * (cell / 4), math.max(1, cell / 4),
            math.max(1, cell / 4), color.withAlpha(a));
      }
    }
  }
}

/// Chão em grade verde, em perspectiva, de [top] até o fim de [area].
void paintGridFloor(Canvas canvas, Rect area, double top, int tick) {
  final p = Paint();
  _rect(canvas, p, area.left, top, area.width, area.bottom - top, const Color(0xFF1E2030));
  final lines = Paint()
    ..color = matrixGreen.withAlpha(90)
    ..strokeWidth = 1;
  final cx = area.center.dx;
  for (var i = -8; i <= 8; i++) {
    canvas.drawLine(Offset(cx + i * 6, top), Offset(cx + i * 30, area.bottom), lines);
  }
  for (var k = 0; k < 4; k++) {
    final y = top + (area.bottom - top) * math.pow((k + (tick % 30) / 30) / 4, 1.6);
    canvas.drawLine(Offset(area.left, y), Offset(area.right, y), lines);
  }
  _rect(canvas, p, area.left, top, area.width, 1, matrixGreen.withAlpha(180));
}

/// O que fica atrás do dev em cada destino, centralizado em [cx] e apoiado
/// em [baseY], com tamanho [u].
void paintPlaceObject(Canvas canvas, Place place, double cx, double baseY, double u, int tick) {
  final p = Paint();
  final accent = Color(place.color);
  void rect(double x, double y, double w, double h, Color c) =>
      _rect(canvas, p, cx + x * u, baseY + y * u, math.max(1, w * u), math.max(1, h * u), c);
  final blink = (tick ~/ 8).isEven;
  switch (place.kind) {
    case PlaceKind.laptop:
      rect(-26, -4, 52, 4, const Color(0xFF3B4261));
      rect(-16, -28, 32, 22, const Color(0xFF737AA2));
      rect(-14, -26, 28, 18, matrixDark);
      for (var i = 0; i < 5; i++) {
        final w = 6.0 + _hash(i + (tick ~/ 20)) % 16;
        rect(-12, -24 + i * 3.4, w, 1.5, i == 4 && blink ? matrixDark : accent);
      }
      rect(-20, -6, 40, 2, const Color(0xFFA9B1D6));
    case PlaceKind.server:
      for (final x in [-24.0, 4.0]) {
        rect(x, -54, 20, 54, const Color(0xFF2F334D));
        for (var y = -50; y < -2; y += 6) {
          rect(x + 2, y.toDouble(), 16, 4, const Color(0xFF3B4261));
          final on = _hash(x.toInt() * 31 + y + tick ~/ 6) % 3;
          rect(x + 3, y + 1.0, 2, 2, on == 0 ? Px.surimiOrange : accent);
          rect(x + 7, y + 1.0, 2, 2, on == 1 ? matrixDark : accent);
        }
      }
    case PlaceKind.cloud:
      p.color = accent.withAlpha(60);
      for (final (x, y, r) in [(-14.0, -40.0, 12.0), (0.0, -46.0, 15.0), (14.0, -40.0, 11.0), (0.0, -34.0, 16.0)]) {
        canvas.drawCircle(Offset(cx + x * u, baseY + y * u), r * u, p);
      }
      for (var i = 0; i < 5; i++) {
        final x = -16.0 + i * 8;
        final y = -24.0 + ((tick * .6 + i * 7) % 20);
        rect(x, y, 1.5, 3, i.isEven ? accent : Px.fujiWhite);
      }
    case PlaceKind.network:
      final c = Offset(cx, baseY - 32 * u), r = 22 * u;
      final stroke = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, u);
      canvas.drawCircle(c, r, stroke);
      for (var k = 1; k < 4; k++) {
        final w = r * 2 * math.cos(k * math.pi / 8 + tick * .02).abs();
        canvas.drawOval(Rect.fromCenter(center: c, width: w, height: r * 2), stroke);
      }
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), stroke);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + tick * .03;
        p.color = i == tick ~/ 10 % 6 ? Px.fujiWhite : accent;
        canvas.drawRect(
            Rect.fromCenter(center: c + Offset(math.cos(a) * r, math.sin(a) * r * .5), width: 3 * u, height: 3 * u), p);
      }
    case PlaceKind.mainframe:
      rect(-30, -44, 60, 44, const Color(0xFFC8D3F5));
      rect(-28, -42, 56, 4, const Color(0xFF3B4261));
      for (final x in [-16.0, 6.0]) {
        p.color = const Color(0xFF2F334D);
        canvas.drawCircle(Offset(cx + x * u + 5 * u, baseY - 26 * u), 8 * u, p);
        p.color = const Color(0xFF737AA2);
        canvas.drawCircle(Offset(cx + x * u + 5 * u, baseY - 26 * u), 3 * u, p);
        final a = tick * .15;
        rect(x + 5 + math.cos(a) * 6, -26 + math.sin(a) * 6, 1.5, 1.5, Px.fujiWhite);
      }
      for (var i = 0; i < 10; i++) {
        rect(-26.0 + i * 5, -10, 3, 3, _hash(i + tick ~/ 5) % 2 == 0 ? accent : Px.autumnRed);
      }
    case PlaceKind.core:
      final pulse = 1 + .12 * math.sin(tick * .12);
      final c = Offset(cx, baseY - 32 * u);
      for (var k = 3; k > 0; k--) {
        p.color = accent.withAlpha(40 * k);
        canvas.drawCircle(c, (8 + k * 6) * u * pulse, p);
      }
      final d = 10 * u * pulse;
      p.color = accent;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - d)
            ..lineTo(c.dx + d, c.dy)
            ..lineTo(c.dx, c.dy + d)
            ..lineTo(c.dx - d, c.dy)
            ..close(),
          p);
      p.color = Px.fujiWhite;
      canvas.drawRect(Rect.fromCenter(center: c, width: 3 * u, height: 3 * u), p);
    case PlaceKind.matrix:
      // falhas na simulação: faixas que piscam
      for (var i = 0; i < 4; i++) {
        final h = _hash(i + tick ~/ 6);
        if (h % 3 != 0) continue;
        rect(-40.0 + h % 50, -60.0 + (h >> 6) % 56, 20.0 + (h >> 3) % 30, 2, accent.withAlpha(140));
      }
  }
}

/// Miniatura de um lugar num quadro [size] (mapa e avisos).
void paintPlaceThumb(Canvas canvas, Place d, Size size, int tick) {
  final p = Paint()..color = matrixDark;
  final area = Offset.zero & size;
  canvas.drawRect(area, p);
  canvas.save();
  canvas.clipRect(area);
  paintRain(canvas, area, 40 + d.index * 13, density: d.kind == PlaceKind.matrix ? .9 : .45, cell: 4, alpha: 150);
  final ground = size.height * .86;
  _rect(canvas, p, 0, ground, size.width, 1, matrixGreen.withAlpha(160));
  paintPlaceObject(canvas, d, size.width / 2, ground, size.height / 70, tick);
  canvas.restore();
}

/// Terminal compilando (tela de carregamento), num quadro 160x90.
void paintLoading(Canvas canvas, double progress, int tick) {
  final p = Paint()..color = matrixDark;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 160, 90), p);
  paintRain(canvas, const Rect.fromLTWH(0, 0, 160, 90), tick, density: .5, cell: 4, alpha: 140);
  _rect(canvas, p, 30, 22, 100, 46, const Color(0xFF737AA2));
  _rect(canvas, p, 31, 23, 98, 6, const Color(0xFF3B4261));
  for (final (i, c) in [(0, Px.autumnRed), (1, Px.boatYellow2), (2, Px.springGreen)]) {
    _rect(canvas, p, 33.0 + i * 4, 25, 2, 2, c);
  }
  _rect(canvas, p, 31, 29, 98, 38, matrixDark);
  final lines = (progress * 8).floor() + 1;
  for (var i = 0; i < math.min(lines, 6); i++) {
    final w = 20.0 + _hash(i + 3) % 60;
    _rect(canvas, p, 34, 32.0 + i * 5, i == lines - 1 ? w * ((progress * 8) % 1) : w, 2, matrixGreen);
  }
  if ((tick ~/ 8).isEven) _rect(canvas, p, 34, 32.0 + math.min(lines, 6) * 5, 3, 3, matrixGreen);
}
