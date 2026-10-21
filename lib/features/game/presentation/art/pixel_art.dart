import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';

/// Grade de pixels: null = transparente.
typedef PixelGrid = List<List<Color?>>;

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _hair = Color(0xFF2E1D14);

/// Astronauta mirim original: capacete grande, rosto no visor,
/// traje com painel de luzes e tanques nas costas.
PixelGrid astronautGrid({
  required int rank,
  required int mk,
  required Map<String, String> equipped,
  bool blink = false,
}) {
  const w = 26, h = 32, ox = 5, oy = 3;
  final g = List.generate(h, (_) => List<Color?>.filled(w, null));
  void r(int x, int y, int rw, int rh, Color c) {
    for (var j = y + oy; j < y + oy + rh; j++) {
      for (var i = x + ox; i < x + ox + rw; i++) {
        if (j >= 0 && j < h && i >= 0 && i < w) g[j][i] = c;
      }
    }
  }

  final suit = Color(suitColor(mk));
  final accent = Color(suitAccent(mk));
  const ink = Kanagawa.sumiInk0;

  // tanques
  r(1, 11, 2, 6, Kanagawa.fujiGray);
  r(13, 11, 2, 6, Kanagawa.fujiGray);
  r(1, 16, 2, 1, Kanagawa.sumiInk6);
  r(13, 16, 2, 1, Kanagawa.sumiInk6);
  // capacete
  r(5, 0, 6, 1, Kanagawa.fujiWhite);
  r(4, 1, 8, 1, Kanagawa.fujiWhite);
  r(3, 2, 10, 7, Kanagawa.fujiWhite);
  r(3, 8, 10, 1, Kanagawa.oldWhite);
  r(4, 9, 8, 1, Kanagawa.oldWhite);
  // visor e rosto
  final golden = equipped['face'] == 'visor';
  r(4, 3, 8, 5, golden ? Kanagawa.carpYellow : Kanagawa.waveBlue1);
  if (!golden) {
    r(5, 4, 6, 3, _skin);
    r(5, 4, 6, 1, _hair);
    r(5, 5, 1, 1, _hair);
    r(6, 5, 1, 1, blink ? _skinDark : ink);
    r(9, 5, 1, 1, blink ? _skinDark : ink);
    r(7, 6, 2, 1, _skinDark);
  }
  r(10, 3, 1, 1, Kanagawa.lightBlue);
  r(11, 4, 1, 1, Kanagawa.lightBlue);
  if (equipped['head'] == 'antenna') {
    r(11, -2, 1, 2, Kanagawa.fujiGray);
    r(11, -3, 1, 1, Kanagawa.autumnRed);
  }
  // corpo
  r(4, 10, 8, 6, suit);
  r(4, 15, 8, 1, accent);
  r(6, 11, 4, 2, ink);
  r(6, 11, 1, 1, Kanagawa.autumnRed);
  r(7, 11, 1, 1, Kanagawa.springGreen);
  r(8, 11, 1, 1, Kanagawa.springBlue);
  r(9, 12, 1, 1, Kanagawa.carpYellow);
  for (var i = 0; i < math.min(5, rank); i++) {
    r(5 + i, 14, 1, 1, Kanagawa.carpYellow);
  }
  if (equipped['body'] == 'stickers') {
    r(10, 11, 1, 2, Kanagawa.surimiOrange);
    r(5, 12, 1, 1, Kanagawa.springBlue);
  }
  // braços
  r(2, 10, 2, 5, suit);
  r(12, 10, 2, 5, suit);
  r(2, 15, 2, 1, accent);
  r(12, 15, 2, 1, accent);
  if (rank >= 2) r(2, 11, 2, 1, accent);
  if (rank >= 3) r(12, 11, 2, 1, Kanagawa.carpYellow);
  // pernas
  r(4, 16, 3, 5, suit);
  r(9, 16, 3, 5, suit);
  r(4, 20, 3, 1, ink);
  r(9, 20, 3, 1, ink);
  r(4, 21, 3, 1, accent);
  r(9, 21, 3, 1, accent);
  if (rank >= 4) {
    r(4, 18, 3, 1, accent);
    r(9, 18, 3, 1, accent);
  }
  if (equipped['hand'] == 'flag') {
    r(14, 6, 1, 10, Kanagawa.fujiGray);
    r(15, 6, 4, 3, Kanagawa.autumnRed);
    r(15, 7, 2, 1, Kanagawa.fujiWhite);
  }
  return _outlined(g, ink);
}

PixelGrid _outlined(PixelGrid g, Color ink) {
  final h = g.length, w = g.first.length;
  final out = [for (final row in g) List<Color?>.of(row)];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (g[y][x] != null) continue;
      final near = (y > 0 && g[y - 1][x] != null) ||
          (y < h - 1 && g[y + 1][x] != null) ||
          (x > 0 && g[y][x - 1] != null) ||
          (x < w - 1 && g[y][x + 1] != null);
      if (near) out[y][x] = ink;
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
      canvas.drawRect(
        Rect.fromLTWH(origin.dx + i * scale, origin.dy + j * scale, scale + 0.3, scale + 0.3),
        paint,
      );
    }
  }
}

void paintPet(Canvas canvas, String id, Offset o) {
  final p = Paint();
  void r(double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(o.dx + x, o.dy + y, w, h), p);
  }

  if (id == 'robot') {
    r(0, 0, 10, 8, Kanagawa.sumiInk0);
    r(1, 1, 8, 6, Kanagawa.springViolet1);
    r(2, 2, 6, 3, Kanagawa.waveBlue1);
    r(3, 3, 1, 1, Kanagawa.springBlue);
    r(6, 3, 1, 1, Kanagawa.springBlue);
    r(4, -2, 1, 2, Kanagawa.sumiInk0);
    r(4, -3, 1, 1, Kanagawa.autumnRed);
    r(2, 8, 6, 2, Kanagawa.sumiInk0);
    r(3, 8, 4, 1, Kanagawa.surimiOrange);
  } else if (id == 'sat') {
    r(0, 2, 4, 3, Kanagawa.springBlue);
    r(4, 1, 4, 5, Kanagawa.sumiInk0);
    r(5, 2, 2, 3, Kanagawa.carpYellow);
    r(8, 2, 4, 3, Kanagawa.springBlue);
    r(5, 0, 2, 1, Kanagawa.fujiWhite);
  }
}

/// Planeta, lua, cinturão ou estrela desenhado em linhas de pixel.
void paintBody(Canvas canvas, Destination d, Offset center, double radius, int tick) {
  final paint = Paint();
  final colors = d.colors.map(Color.new).toList();
  final seed = seedHash(d.index + 7);
  final cx = center.dx, cy = center.dy;
  final r = radius.roundToDouble();

  void rect(double x, double y, double w, double h, Color c) {
    paint.color = c;
    canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w, h), paint);
  }

  if (d.kind == BodyKind.belt) {
    for (var n = 0; n < 14; n++) {
      final a = n * 2.39 + tick * 0.002;
      final rr = r * (0.4 + ((seed >> n) % 60) / 100);
      final s = math.max(1.0, (r / 7).roundToDouble() + n % 3);
      rect(cx + math.cos(a) * rr, cy + math.sin(a) * rr * 0.5, s, s, colors[n % 2]);
    }
    return;
  }
  final ringH = math.max(1.0, (r * 0.24).roundToDouble());
  if (d.kind == BodyKind.ring) rect(cx - r * 1.7, cy - ringH / 2, r * 3.4, ringH, colors[1]);
  if (d.kind == BodyKind.star) {
    paint.color = colors[1].withAlpha(64);
    canvas.drawCircle(center, r * 1.4, paint);
  }
  for (var yy = -r; yy <= r; yy++) {
    final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
    if (hw <= 0) continue;
    var c = colors[0];
    final yi = yy.toInt();
    if (d.kind == BodyKind.gas) {
      final band = ((yy + r) ~/ math.max(2, r / 4)) % colors.length;
      c = colors[band];
    } else if (d.kind == BodyKind.earth && (yi * 7 + seed) % 9 < 3) {
      c = colors[1];
    } else if (d.kind == BodyKind.rocky && (yi + seed) % 6 == 0) {
      c = colors[1];
    }
    rect(cx - hw, cy + yy, hw * 2, 1, c);
  }
  if (d.kind == BodyKind.moon || d.kind == BodyKind.rocky) {
    final s = math.max(1.0, (r / 6).roundToDouble());
    for (var n = 0; n < 6; n++) {
      final a = ((seed >> (n * 3)) % 628) / 100;
      final rr = r * (((seed >> (n * 2)) % 70) / 100);
      rect(cx + math.cos(a) * rr, cy + math.sin(a) * rr, s, s, colors[1]);
    }
  }
  if (d.kind == BodyKind.earth) {
    rect(cx - r * 0.3, cy - r + 1, r * 0.6, math.max(1.0, (r * 0.1).roundToDouble()), Kanagawa.fujiWhite);
  }
  if (d.kind == BodyKind.ring) {
    rect(cx - r * 1.7, cy - ringH / 2, r * 0.9, ringH, colors[1]);
    rect(cx + r * 0.8, cy - ringH / 2, r * 0.9, ringH, colors[1]);
  }
  if (d.name == 'Júpiter') {
    rect(cx + r * 0.2, cy + r * 0.25, math.max(2.0, r * 0.3), math.max(1.0, r * 0.15), Kanagawa.autumnRed);
  }
  // sombra
  paint.color = const Color(0x5916161D);
  for (var yy = -r; yy <= r; yy++) {
    final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
    if (hw > 0) {
      canvas.drawRect(Rect.fromLTWH((cx + hw * 0.35).roundToDouble(), cy + yy, hw * 0.65, 1), paint);
    }
  }
}

/// Chefe da semana: uma criatura espacial simples.
void paintBoss(Canvas canvas, Color color, bool defeated) {
  final p = Paint();
  void r(double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(x, y, w, h), p);
  }

  const ink = Kanagawa.sumiInk0;
  const white = Kanagawa.fujiWhite;
  r(8, 10, 24, 24, ink);
  r(9, 11, 22, 22, defeated ? Kanagawa.sumiInk6 : color);
  r(10, 6, 4, 6, ink);
  r(11, 7, 2, 4, white);
  r(26, 6, 4, 6, ink);
  r(27, 7, 2, 4, white);
  if (defeated) {
    r(13, 17, 5, 1, ink);
    r(15, 15, 1, 5, ink);
    r(22, 17, 5, 1, ink);
    r(24, 15, 1, 5, ink);
  } else {
    r(13, 16, 5, 4, ink);
    r(14, 17, 2, 2, white);
    r(22, 16, 5, 4, ink);
    r(24, 17, 2, 2, white);
  }
  r(14, 24, 12, 3, ink);
  r(15, 24, 2, 2, white);
  r(23, 24, 2, 2, white);
}

void paintChest(Canvas canvas, Color band, bool open) {
  final p = Paint();
  void r(double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(x, y, w, h), p);
  }

  const wood = Color(0xFF8A5A2B);
  const lid = Color(0xFFA86E36);
  r(4, 14, 24, 14, Kanagawa.sumiInk0);
  r(5, 15, 22, 12, wood);
  r(5, 20, 22, 2, band);
  r(14, 18, 4, 6, band);
  if (open) {
    r(4, 4, 24, 8, Kanagawa.sumiInk0);
    r(5, 5, 22, 6, lid);
    r(8, 12, 16, 3, Kanagawa.carpYellow);
  } else {
    r(4, 8, 24, 8, Kanagawa.sumiInk0);
    r(5, 9, 22, 6, lid);
    r(5, 13, 22, 2, band);
  }
}
