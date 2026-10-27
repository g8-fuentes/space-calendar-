import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/places.dart';

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

void _rect(Canvas canvas, Paint p, double x, double y, double w, double h, Color c) {
  p.color = c;
  canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w.roundToDouble(), h.roundToDouble()), p);
}

/// Triângulo em degraus de pixel, com base em [baseY].
void _tri(Canvas canvas, Paint p, double cx, double baseY, double baseW, double h, Color c) {
  for (var i = 0; i < h; i++) {
    final w = math.max(1.0, baseW * (1 - i / h));
    _rect(canvas, p, cx - w / 2, baseY - i - 1, w, 1, c);
  }
}

/// Planeta, lua ou estrela desenhado em linhas de pixel.
void paintBody(Canvas canvas, Place d, Offset center, double radius, int tick) {
  final paint = Paint();
  final colors = d.colors.map(Color.new).toList();
  final c2 = colors.length > 1 ? colors[1] : colors[0];
  final seed = placeHash(d.index + 7);
  final cx = center.dx, cy = center.dy;
  final r = radius.roundToDouble();

  void rect(double x, double y, double w, double h, Color c) => _rect(canvas, paint, x, y, w, h, c);

  final ringH = math.max(1.0, (r * 0.24).roundToDouble());
  if (d.kind == PlaceKind.ring) rect(cx - r * 1.7, cy - ringH / 2, r * 3.4, ringH, c2);
  if (d.kind == PlaceKind.star) {
    paint.color = c2.withAlpha(50);
    canvas.drawCircle(center, r * 1.8, paint);
    paint.color = colors[0].withAlpha(70);
    canvas.drawCircle(center, r * 1.35, paint);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + tick * .004;
      final len = r * (i.isEven ? .9 : .55) * (1 + .08 * math.sin(tick * .1 + i));
      for (var k = 0.0; k < len; k += 1) {
        rect(cx + math.cos(a) * (r + 2 + k), cy + math.sin(a) * (r + 2 + k), 1, 1,
            colors[0].withAlpha((200 * (1 - k / len)).round()));
      }
    }
  }
  for (var yy = -r; yy <= r; yy++) {
    final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
    if (hw <= 0) continue;
    var c = colors[0];
    final yi = yy.toInt();
    if (d.kind == PlaceKind.gas) {
      c = colors[((yy + r) ~/ math.max(2, r / 5)) % colors.length];
    } else if (d.kind == PlaceKind.earth && (yi * 7 + seed) % 9 < 3) {
      c = c2;
    } else if (d.kind == PlaceKind.rocky && (yi + seed) % 6 == 0) {
      c = c2;
    } else if (d.kind == PlaceKind.star && yy.abs() < r * .5 && (yi + tick ~/ 6) % 5 == 0) {
      c = c2;
    }
    rect(cx - hw, cy + yy, hw * 2, 1, c);
  }
  if (d.kind == PlaceKind.earth) {
    // nuvens
    for (var n = 0; n < 5; n++) {
      final y = cy - r * .7 + n * r * .33;
      final w = r * (.3 + ((seed >> n) % 40) / 100);
      final x = cx - r + ((seed >> (n * 3)) % 100) / 100 * r * 1.4 + tick * .02 % r;
      final hw = math.sqrt(math.max(0, r * r - (y - cy) * (y - cy)));
      final x0 = math.max(cx - hw, x), x1 = math.min(cx + hw, x + w);
      if (x1 > x0) rect(x0, y, x1 - x0, math.max(1, r / 14), Kanagawa.fujiWhite.withAlpha(200));
    }
  }
  if (d.kind == PlaceKind.moon || d.kind == PlaceKind.rocky) {
    final s = math.max(1.0, (r / 6).roundToDouble());
    for (var n = 0; n < 7; n++) {
      final a = ((seed >> (n * 3)) % 628) / 100;
      final rr = r * (((seed >> (n * 2)) % 70) / 100);
      rect(cx + math.cos(a) * rr, cy + math.sin(a) * rr, s, s, c2);
    }
  }
  if (d.kind == PlaceKind.ring) {
    rect(cx - r * 1.7, cy - ringH / 2, r * 0.9, ringH, c2);
    rect(cx + r * 0.8, cy - ringH / 2, r * 0.9, ringH, c2);
  }
  if (d.kind != PlaceKind.star) {
    paint.color = const Color(0x5916161D);
    for (var yy = -r; yy <= r; yy++) {
      final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
      if (hw > 0) canvas.drawRect(Rect.fromLTWH((cx + hw * 0.35).roundToDouble(), cy + yy, hw * 0.65, 1), paint);
    }
  }
}

/// Constelação dentro de [area]: linhas fracas e estrelas piscando.
void paintConstellation(Canvas canvas, Place d, Rect area, int tick, {double alpha = 1}) {
  final p = Paint();
  final c = Color(d.colors.first);
  Offset at((double, double, int) s) => Offset(area.left + s.$1 * area.width, area.top + s.$2 * area.height);
  final line = Paint()
    ..color = c.withAlpha((90 * alpha).round())
    ..strokeWidth = math.max(.6, area.shortestSide / 110);
  for (final (a, b) in d.lines) {
    canvas.drawLine(at(d.stars[a]), at(d.stars[b]), line);
  }
  for (var i = 0; i < d.stars.length; i++) {
    final s = d.stars[i];
    final o = at(s);
    final tw = .7 + .3 * math.sin(tick * .08 + i * 1.9);
    final size = s.$3 * area.shortestSide / 60;
    p.color = c.withAlpha((60 * tw * alpha).round());
    canvas.drawCircle(o, size * 2.4, p);
    p.color = Kanagawa.fujiWhite.withAlpha((255 * tw * alpha).round());
    canvas.drawRect(Rect.fromCenter(center: o, width: size, height: size), p);
    if (s.$3 >= 2) {
      p.color = Kanagawa.fujiWhite.withAlpha((150 * tw * alpha).round());
      canvas.drawRect(Rect.fromCenter(center: o, width: size * 3.2, height: math.max(.5, size / 3)), p);
      canvas.drawRect(Rect.fromCenter(center: o, width: math.max(.5, size / 3), height: size * 3.2), p);
    }
  }
}

/// Prédios da cidade (fundo e frente) e o monumento, apoiados em [groundY].
/// [night] acende as janelas.
void paintSkyline(Canvas canvas, Place city, double groundY, double width,
    {required double night, double unit = 1, double? landmarkUnit}) {
  final p = Paint();
  final seed = placeHash(city.index + 101);
  final r = math.Random(seed);
  final accent = Color(city.colors.first);
  final back = Color.lerp(const Color(0xFF3B4A63), Kanagawa.sumiInk5, night)!;
  final front = Color.lerp(const Color(0xFF2A3346), Kanagawa.sumiInk4, night)!;
  // fundo
  var x = 0.0;
  while (x < width) {
    final w = (8 + r.nextInt(14)) * unit, h = (14 + r.nextInt(26)) * unit;
    _rect(canvas, p, x, groundY - h, w, h, back);
    x += w + r.nextInt(3) * unit;
  }
  paintLandmark(canvas, city.landmark, width * .72, groundY, landmarkUnit ?? unit, accent);
  // frente, deixando o centro livre para o personagem e o monumento
  x = 0;
  while (x < width) {
    final w = (10 + r.nextInt(12)) * unit, h = (8 + r.nextInt(16)) * unit;
    final skip = (x > width * .58 && x < width * .86);
    if (!skip) {
      _rect(canvas, p, x, groundY - h, w, h, front);
      for (var wy = groundY - h + 3 * unit; wy < groundY - 3 * unit; wy += 4 * unit) {
        for (var wx = x + 2 * unit; wx < x + w - 2 * unit; wx += 4 * unit) {
          final lit = night > .5 && r.nextInt(3) > 0;
          _rect(
              canvas,
              p,
              wx,
              wy,
              2 * unit,
              2 * unit,
              lit
                  ? Kanagawa.carpYellow.withAlpha(220)
                  : Color.lerp(const Color(0xFF7FB4CA), Kanagawa.sumiInk6, night)!.withAlpha(140));
        }
      }
    }
    x += w + (1 + r.nextInt(3)) * unit;
  }
}

/// Monumento de cada cidade, centralizado em [cx] e apoiado em [baseY].
void paintLandmark(Canvas canvas, Landmark l, double cx, double baseY, double u, Color accent) {
  final p = Paint();
  void rect(double x, double y, double w, double h, Color c) =>
      _rect(canvas, p, cx + x * u, baseY + y * u, w * u, h * u, c);
  void tri(double x, double baseW, double h, Color c, [double y = 0]) =>
      _tri(canvas, p, cx + x * u, baseY + y * u, baseW * u, h * u, c);
  const stone = Color(0xFFC8C093), dark = Kanagawa.sumiInk3;
  switch (l) {
    case Landmark.none:
      break;
    case Landmark.obelisk:
      rect(-2, -38, 4, 38, stone);
      tri(0, 4, 4, stone, -38);
      rect(-4, -2, 8, 2, Kanagawa.fujiGray);
    case Landmark.cityTower:
      rect(-6, -40, 12, 40, const Color(0xFF7E8BA3));
      rect(-4, -46, 8, 6, const Color(0xFF7E8BA3));
      rect(-1, -58, 2, 12, Kanagawa.fujiGray);
      rect(-1, -59, 2, 1, Kanagawa.autumnRed);
      for (var y = -38; y < -2; y += 4) {
        rect(-4, y.toDouble(), 8, 1, dark);
      }
    case Landmark.christ:
      tri(0, 70, 26, const Color(0xFF4F6F3E));
      tri(0, 40, 18, const Color(0xFF5E8049));
      rect(-1, -36, 2, 10, stone);
      rect(-7, -33, 14, 2, stone);
      rect(-1, -38, 2, 2, stone);
    case Landmark.needle:
      rect(-7, -24, 14, 24, const Color(0xFF8FA3BF));
      rect(-5, -40, 10, 16, const Color(0xFF8FA3BF));
      rect(-3, -54, 6, 14, const Color(0xFFA3B6CF));
      rect(-1, -66, 2, 12, Kanagawa.fujiWhite);
      for (var y = -52; y < 0; y += 5) {
        rect(-1, y.toDouble(), 2, 1, Kanagawa.lightBlue);
      }
    case Landmark.ironTower:
      for (var i = 0; i < 52; i++) {
        final w = 24 * math.pow(1 - i / 52, 1.6).toDouble() + 2;
        final y = -i - 1.0;
        rect(-w / 2, y, 2, 1, accent);
        rect(w / 2 - 2, y, 2, 1, accent);
        if (i == 14 || i == 30) rect(-w / 2, y, w, 2, accent);
      }
      rect(-.5, -58, 1, 6, accent);
    case Landmark.clockTower:
      rect(-5, -44, 10, 44, stone);
      rect(-6, -36, 12, 10, const Color(0xFFB9A774));
      p.color = Kanagawa.fujiWhite;
      canvas.drawCircle(Offset(cx, baseY - 31 * u), 3.5 * u, p);
      rect(-.5, -34, 1, 3, dark);
      rect(-.5, -31.5, 2.5, 1, dark);
      tri(0, 10, 12, const Color(0xFF54546D), -44);
    case Landmark.coliseum:
      rect(-24, -20, 48, 20, stone);
      rect(-24, -22, 30, 2, stone);
      for (var row = 0; row < 3; row++) {
        for (var i = 0; i < 8; i++) {
          rect(-22.0 + i * 6, -18.0 + row * 6, 3, 4, const Color(0xFF8C7A53));
        }
      }
    case Landmark.pyramids:
      tri(-12, 46, 30, const Color(0xFFE6C384));
      tri(-12, 46, 30, const Color(0x33C0A36E));
      tri(18, 30, 19, const Color(0xFFD4B472));
      rect(-12, -30, 1, 1, Kanagawa.fujiWhite);
    case Landmark.onionDome:
      for (final (x, h, c) in [
        (-12.0, 28.0, Kanagawa.autumnRed),
        (0.0, 38.0, Kanagawa.springGreen),
        (12.0, 26.0, Kanagawa.crystalBlue)
      ]) {
        rect(x - 4, -h, 8, h, const Color(0xFFC88A6E));
        p.color = c;
        canvas.drawCircle(Offset(cx + x * u, baseY - (h + 4) * u), 5.5 * u, p);
        rect(x - .5, -h - 14, 1, 5, Kanagawa.carpYellow);
      }
    case Landmark.pagoda:
      for (var i = 0; i < 4; i++) {
        final w = 34.0 - i * 7, y = -8.0 - i * 10;
        rect(-w / 2 + 3, y, w - 6, 8, Kanagawa.autumnRed);
        rect(-w / 2, y - 2, w, 2, const Color(0xFF3F5F4A));
        rect(-w / 2 - 1, y - 3, 2, 1, const Color(0xFF3F5F4A));
        rect(w / 2 - 1, y - 3, 2, 1, const Color(0xFF3F5F4A));
      }
      rect(-.5, -54, 1, 6, Kanagawa.carpYellow);
    case Landmark.dome:
      rect(-16, -14, 32, 14, Kanagawa.fujiWhite);
      p.color = Kanagawa.fujiWhite;
      canvas.drawCircle(Offset(cx, baseY - 20 * u), 9 * u, p);
      rect(-.5, -34, 1, 5, Kanagawa.carpYellow);
      for (final x in [-20.0, 19.0]) {
        rect(x, -30, 2, 30, Kanagawa.fujiWhite);
      }
      rect(-3, -10, 6, 10, const Color(0xFF8C7A53));
    case Landmark.opera:
      rect(-26, -4, 52, 4, stone);
      for (final (x, w, h) in [(-16.0, 16.0, 18.0), (-4.0, 18.0, 24.0), (9.0, 16.0, 20.0), (19.0, 12.0, 14.0)]) {
        for (var i = 0; i < h; i++) {
          final wi = w * (1 - i / h);
          rect(x - wi / 2 + (i / h) * w * .35, -4 - i - 1.0, wi, 1,
              i.isEven ? Kanagawa.fujiWhite : const Color(0xFFE4DFC6));
        }
      }
  }
}

/// Foguete decolando (tela de carregamento), num quadro 160x90.
void paintLaunch(Canvas canvas, double progress, int tick) {
  final p = Paint()..color = _ink;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 160, 90), p);
  for (var i = 0; i < 40; i++) {
    p.color = i % 4 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
    final y = ((i * 23) + progress * 400 * (1 + i % 3)) % 90;
    canvas.drawRect(Rect.fromLTWH(((i * 37) % 160).toDouble(), y, 1, i % 5 == 0 ? 3 : 1), p);
  }
  final ry = 70 - progress * 30 + math.sin(progress * 40);
  void r(double a, double b, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(74 + a, ry + b, w, h), p);
  }

  r(2, -16, 8, 22, _ink);
  r(3, -15, 6, 20, Kanagawa.fujiWhite);
  r(4, -19, 4, 4, Kanagawa.autumnRed);
  r(4, -8, 4, 4, Kanagawa.waveBlue1);
  r(5, -7, 2, 2, Kanagawa.springBlue);
  r(-1, 0, 4, 7, Kanagawa.autumnRed);
  r(9, 0, 4, 7, Kanagawa.autumnRed);
  final fl = 6.0 + (tick % 5);
  r(4, 6, 4, fl, Kanagawa.surimiOrange);
  r(5, 6, 2, fl - 2, Kanagawa.carpYellow);
}

/// Miniatura de um lugar num quadro [size] (mapa e avisos).
void paintPlaceThumb(Canvas canvas, Place d, Size size, int tick) {
  final p = Paint()..color = d.region == Region.earth ? const Color(0xFF2D4F67) : _ink;
  canvas.drawRect(Offset.zero & size, p);
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  switch (d.kind) {
    case PlaceKind.city:
      final u = size.height / 70;
      paintSkyline(canvas, d, size.height - 4 * u, size.width, night: 0, unit: u);
      p.color = const Color(0xFF3A3A44);
      canvas.drawRect(Rect.fromLTWH(0, size.height - 4 * u, size.width, 4 * u), p);
    case PlaceKind.constellation:
      paintConstellation(canvas, d, (Offset.zero & size).deflate(size.shortestSide * .12), tick);
    default:
      paintBody(canvas, d, size.center(Offset.zero), size.shortestSide * (d.kind == PlaceKind.ring ? .22 : .3), tick);
  }
  canvas.restore();
}
