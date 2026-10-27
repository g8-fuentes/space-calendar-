import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart' show hslToArgb;
import '../../domain/catalog/transformations.dart';
import 'pixel_art.dart';

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _ink = Kanagawa.sumiInk0;

/// Grade do personagem: 26 x 34, com a figura entre as colunas 6 e 20
/// e os pés na linha 30 (há espaço em cima para o cabelo em chamas).
const gridW = 26, gridH = 34, _ox = 5, _oy = 9;

/// Linha dos pés na grade.
const feetRow = _oy + 21;

/// Cor de aura e cabelo, com o ciclo de cores das formas cósmicas.
Color auraOf(Transformation f, int tick) =>
    f.cosmic ? Color(hslToArgb(((tick * 3) % 360).toDouble(), .75, .65)) : Color(f.auraColor);

Color hairOf(Transformation f, int tick) =>
    f.cosmic ? Color(hslToArgb(((tick * 3 + 180) % 360).toDouble(), .7, .7)) : Color(f.hairColor);

typedef _R = void Function(int x, int y, int w, int h, Color c);

(PixelGrid, _R) _canvas() {
  final g = List.generate(gridH, (_) => List<Color?>.filled(gridW, null));
  void r(int x, int y, int rw, int rh, Color c) {
    for (var j = y + _oy; j < y + _oy + rh; j++) {
      for (var i = x + _ox; i < x + _ox + rw; i++) {
        if (j >= 0 && j < gridH && i >= 0 && i < gridW) g[j][i] = c;
      }
    }
  }

  return (g, r);
}

void _spikes(_R r, Color hair) {
  r(4, 0, 8, 2, hair);
  r(4, 2, 1, 3, hair);
  r(11, 2, 1, 3, hair);
  r(4, -2, 2, 2, hair);
  r(5, -4, 1, 2, hair);
  r(7, -3, 2, 3, hair);
  r(8, -5, 1, 2, hair);
  r(10, -2, 2, 2, hair);
  r(10, -4, 1, 2, hair);
  r(3, 1, 1, 2, hair);
  r(12, 1, 1, 2, hair);
  r(2, 2, 1, 1, hair);
  r(13, 2, 1, 1, hair);
  r(5, 2, 1, 2, hair);
  r(9, 2, 1, 1, hair);
}

void _wild(_R r, Color hair) {
  _spikes(r, hair);
  r(2, 0, 1, 4, hair);
  r(13, 0, 1, 4, hair);
  r(1, 1, 1, 2, hair);
  r(14, 1, 1, 2, hair);
  r(0, 2, 1, 1, hair);
  r(15, 2, 1, 1, hair);
  r(3, -3, 2, 3, hair);
  r(11, -3, 2, 3, hair);
  r(2, -4, 1, 2, hair);
  r(13, -4, 1, 2, hair);
  r(6, -6, 1, 3, hair);
  r(9, -6, 1, 4, hair);
  r(3, 2, 1, 5, hair);
  r(12, 2, 1, 5, hair);
}

void _flame(_R r, Color hair, Color tip, int tick) {
  _spikes(r, hair);
  final f = (tick ~/ 6) % 2;
  r(4, -5, 1, 3, hair);
  r(11, -5, 1, 3, hair);
  r(5, -7 + f, 1, 3, hair);
  r(7, -8, 2, 5, hair);
  r(8, -9 + f, 1, 1, tip);
  r(10, -7 + f, 1, 3, hair);
  r(6, -6, 1, 2, hair);
  r(9, -6, 1, 2, hair);
  r(5, -7 + f, 1, 1, tip);
  r(10, -7 + f, 1, 1, tip);
  r(3, -3, 1, 3, hair);
  r(12, -3, 1, 3, hair);
}

/// Logo </> de dev no peito.
void _dev(_R r, Color c) {
  for (final (x, y) in const [(5, 11), (4, 12), (5, 13), (8, 11), (7, 12), (7, 13), (10, 11), (11, 12), (10, 13)]) {
    r(x, y, 1, 1, c);
  }
}

/// O dev lutador: roupa e cabelo mudam com a transformação.
PixelGrid personGrid(Transformation f, {bool blink = false, int tick = 0}) {
  final (g, r) = _canvas();
  final hair = hairOf(f, tick);
  final eyes = Color(f.eyes);
  if (f.hair == Hair.long) {
    r(3, 2, 10, 15, hair);
    r(4, 17, 8, 2, hair);
  }
  if (f.outfit == Outfit.giCape || f.outfit == Outfit.divine) {
    final cape = f.outfit == Outfit.divine ? const Color(0xFF7E9CD8) : Kanagawa.autumnRed;
    r(3, 10, 10, 11, cape);
    r(2, 15, 12, 6, cape);
    r(2, 20, 12, 1, Color.lerp(cape, _ink, .35)!);
  }
  // cabeça
  r(5, 2, 6, 7, _skin);
  r(4, 5, 1, 2, _skin);
  r(11, 5, 1, 2, _skin);
  switch (f.hair) {
    case Hair.normal:
      r(4, 0, 8, 2, hair);
      r(4, 2, 1, 3, hair);
      r(11, 2, 1, 2, hair);
      r(5, 2, 3, 1, hair);
    case Hair.spiky || Hair.long:
      _spikes(r, hair);
    case Hair.wild:
      _wild(r, hair);
    case Hair.flame:
      _flame(r, hair, auraOf(f, tick), tick);
  }
  r(6, 5, 1, 1, blink ? _skinDark : eyes);
  r(9, 5, 1, 1, blink ? _skinDark : eyes);
  r(7, 7, 2, 1, _skinDark);
  r(7, 9, 2, 1, _skin);
  // roupa
  switch (f.outfit) {
    case Outfit.casual:
      const shirt = Color(0xFF7E9CD8), jeans = Color(0xFF2D4F67);
      r(4, 10, 8, 6, shirt);
      r(2, 10, 2, 2, shirt);
      r(12, 10, 2, 2, shirt);
      r(2, 12, 2, 4, _skin);
      r(12, 12, 2, 4, _skin);
      r(4, 16, 8, 1, jeans);
      r(4, 17, 3, 4, jeans);
      r(9, 17, 3, 4, jeans);
      r(3, 21, 4, 1, Kanagawa.fujiWhite);
      r(9, 21, 4, 1, Kanagawa.fujiWhite);
      _dev(r, Kanagawa.fujiWhite);
    case Outfit.training:
      const hoodie = Color(0xFF727169), pants = Color(0xFF1F1F28);
      r(4, 10, 8, 6, hoodie);
      r(2, 10, 2, 5, hoodie);
      r(12, 10, 2, 5, hoodie);
      r(4, 15, 8, 1, Kanagawa.autumnRed);
      _dev(r, Kanagawa.carpYellow);
      r(2, 15, 2, 1, _skin);
      r(12, 15, 2, 1, _skin);
      r(7, 10, 2, 1, Kanagawa.fujiWhite);
      r(4, 16, 8, 1, pants);
      r(4, 17, 3, 4, pants);
      r(9, 17, 3, 4, pants);
      r(3, 21, 4, 1, Kanagawa.autumnRed);
      r(9, 21, 4, 1, Kanagawa.autumnRed);
    case Outfit.gi || Outfit.giCape:
      const gi = Color(0xFFFFA066), blue = Color(0xFF223249);
      r(4, 10, 8, 6, gi);
      r(7, 10, 2, 1, blue);
      r(4, 15, 8, 1, blue);
      r(2, 10, 2, 2, gi);
      r(12, 10, 2, 2, gi);
      r(2, 12, 2, 2, _skin);
      r(12, 12, 2, 2, _skin);
      r(2, 14, 2, 1, blue);
      r(12, 14, 2, 1, blue);
      r(2, 15, 2, 1, _skin);
      r(12, 15, 2, 1, _skin);
      r(4, 16, 8, 1, gi);
      r(4, 17, 3, 3, gi);
      r(9, 17, 3, 3, gi);
      r(3, 20, 4, 2, blue);
      r(9, 20, 4, 2, blue);
      r(3, 20, 4, 1, Kanagawa.autumnRed);
      r(9, 20, 4, 1, Kanagawa.autumnRed);
      _dev(r, blue);
      if (f.outfit == Outfit.giCape) {
        r(4, 10, 1, 1, Kanagawa.carpYellow);
        r(11, 10, 1, 1, Kanagawa.carpYellow);
      }
    case Outfit.divine:
      const robe = Color(0xFFE4DFC6), sash = Color(0xFF7E9CD8), navy = Color(0xFF223249);
      r(4, 10, 8, 6, robe);
      r(4, 14, 8, 2, sash);
      r(7, 10, 2, 3, navy);
      r(2, 10, 2, 4, robe);
      r(12, 10, 2, 4, robe);
      r(2, 14, 2, 2, _skin);
      r(12, 14, 2, 2, _skin);
      r(4, 16, 8, 1, navy);
      r(4, 17, 3, 4, navy);
      r(9, 17, 3, 4, navy);
      r(3, 21, 4, 1, robe);
      r(9, 21, 4, 1, robe);
      _dev(r, sash);
  }
  return outlined(g);
}

final _grids = <String, PixelGrid>{};

/// Grade do personagem na transformação [f].
PixelGrid characterGrid(Transformation f, {bool blink = false, int tick = 0}) {
  final t = f.cosmic ? tick ~/ 4 * 4 : (f.hair == Hair.flame ? tick ~/ 6 * 6 % 12 : 0);
  final key = '${f.index}|$blink|$t';
  if (_grids.length > 40) _grids.clear();
  return _grids[key] ??= personGrid(f, blink: blink, tick: t);
}

/// Caixa ocupada pela figura (do topo do cabelo aos pés) com a grade em
/// [origin] e escala [sc].
Rect figureBox(Offset origin, double sc) =>
    Rect.fromLTWH(origin.dx + 7 * sc, origin.dy + (_oy - 5) * sc, 12 * sc, 27 * sc);

/// Força da aura; no espaço ele sempre voa com pelo menos um brilho.
int auraLevel(Transformation f, {bool space = false}) => space ? math.max(1, f.aura) : f.aura;

class AuraParticle {
  AuraParticle(this.x, this.y, this.vx, this.vy, this.life, this.size);
  double x, y, vx, vy, life;
  final double size;
}

/// Chamas da aura subindo em volta de [box], com força [level].
void stepAura(List<AuraParticle> list, Rect box, Transformation f, int level, math.Random rand) {
  final n = const [0, 1, 3, 5, 6, 8][level.clamp(0, 5)];
  final spread = level >= 5 ? .2 : .08;
  for (var i = 0; i < n; i++) {
    final side = rand.nextBool();
    final x = side
        ? box.left + rand.nextDouble() * box.width * .3 - box.width * spread
        : box.right - rand.nextDouble() * box.width * .3 + box.width * spread;
    final y = box.top + box.height * (.15 + rand.nextDouble() * .85);
    list.add(AuraParticle(
        x,
        y,
        (side ? -.08 : .08) * rand.nextDouble(),
        -(.5 + rand.nextDouble() * .7) * (1 + math.min(level, 3) * .3),
        14 + rand.nextDouble() * 20,
        rand.nextDouble() < .35 ? 3 : 2));
  }
  for (final p in list) {
    p
      ..life -= 1
      ..x += p.vx
      ..y += p.vy;
  }
  list.removeWhere((p) => p.life <= 0);
  if (list.length > 320) list.removeRange(0, list.length - 320);
}

Path _flameShape(Rect box, double wScale, double hScale, int tick) {
  final h = box.height * hScale * (1 + .035 * math.sin(tick * .3));
  final w = box.width * wScale;
  final cx = box.center.dx;
  return Path()
    ..moveTo(cx - w / 2, box.bottom)
    ..quadraticBezierTo(cx - w * .62, box.bottom - h * .55, cx - w * .2, box.bottom - h * .92)
    ..lineTo(cx - w * .1, box.bottom - h * .82)
    ..lineTo(cx, box.bottom - h)
    ..lineTo(cx + w * .1, box.bottom - h * .82)
    ..lineTo(cx + w * .2, box.bottom - h * .92)
    ..quadraticBezierTo(cx + w * .62, box.bottom - h * .55, cx + w / 2, box.bottom)
    ..close();
}

/// Brilho, chamas e faíscas atrás do personagem.
void paintAuraBack(Canvas canvas, Rect box, Transformation f, int level, List<AuraParticle> list, int tick) {
  if (level <= 0) return;
  final c = auraOf(f, tick);
  final p = Paint();
  final pulse = .85 + .15 * math.sin(tick * .15);
  final glow = math.min(level, 3);
  p.color = c.withAlpha((28 * glow * pulse).round());
  canvas.drawOval(Rect.fromCenter(center: box.center, width: box.width * 2.1, height: box.height * 1.35), p);
  p.color = c.withAlpha((34 * glow * pulse).round());
  canvas.drawOval(
      Rect.fromCenter(
          center: box.center.translate(0, box.height * .05), width: box.width * 1.5, height: box.height * 1.15),
      p);
  if (level >= 5) {
    p.color = c.withAlpha((45 * pulse).round());
    canvas.drawPath(_flameShape(box, 2.6, 1.45, tick + 7), p);
  }
  if (level >= 2) {
    p.color = c.withAlpha((60 * pulse).round());
    canvas.drawPath(_flameShape(box, 1.7, 1.18, tick), p);
  }
  if (level >= 3) {
    p.color = Color.lerp(c, Kanagawa.fujiWhite, .5)!.withAlpha((40 * pulse).round());
    canvas.drawPath(_flameShape(box, 1.25, 1.05, tick + 3), p);
  }
  for (final a in list) {
    p.color = c.withAlpha((math.min(1.0, a.life / 14) * 230).round());
    canvas.drawRect(Rect.fromLTWH(a.x.roundToDouble(), a.y.roundToDouble(), a.size, a.size * 1.6), p);
  }
  if (level >= 4) {
    // anel de faíscas em volta
    final n = level >= 5 ? 14 : 10;
    for (var i = 0; i < n; i++) {
      final ang = tick * .06 + i * 2 * math.pi / n;
      final front = math.sin(ang) > 0;
      if (front) continue;
      _spark(canvas, p, box, ang, c);
    }
  }
}

void _spark(Canvas canvas, Paint p, Rect box, double ang, Color c) {
  final s = math.max(2.0, box.width / 10);
  final x = box.center.dx + math.cos(ang) * box.width * 1.05;
  final y = box.center.dy + box.height * .12 + math.sin(ang) * box.height * .12;
  p.color = Color.lerp(c, Kanagawa.fujiWhite, .4)!;
  canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), s, s), p);
}

/// Raios e a frente do anel de faíscas.
void paintAuraFront(Canvas canvas, Rect box, Transformation f, int level, int tick) {
  if (level >= 4) {
    final c = auraOf(f, tick), p = Paint();
    final n = level >= 5 ? 14 : 10;
    for (var i = 0; i < n; i++) {
      final ang = tick * .06 + i * 2 * math.pi / n;
      if (math.sin(ang) > 0) _spark(canvas, p, box, ang, c);
    }
  }
  if (!f.lightning || tick % 9 > 3) return;
  final r = math.Random(tick ~/ 4);
  final p = Paint()
    ..color = (tick ~/ 4).isEven ? Kanagawa.lightBlue : Kanagawa.fujiWhite
    ..strokeWidth = math.max(1, box.width / 22)
    ..style = PaintingStyle.stroke;
  for (var k = 0; k < (level >= 4 ? 3 : 2); k++) {
    var x = box.left + r.nextDouble() * box.width, y = box.top + r.nextDouble() * box.height * .4;
    final path = Path()..moveTo(x, y);
    for (var i = 0; i < 4; i++) {
      x += (r.nextDouble() - .5) * box.width * .5;
      y += box.height * (.08 + r.nextDouble() * .12);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, p);
  }
}
