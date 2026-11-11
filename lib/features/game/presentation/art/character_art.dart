import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart' show hslToArgb;
import '../../domain/catalog/transformations.dart';
import 'pixel_art.dart';

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _hair = Color(0xFF2E1D14);
const _ink = Px.sumiInk0;

/// Grade do personagem: 26 x 34, com a figura entre as colunas 6 e 20
/// e os pés na linha 30 (há espaço em volta para a aura).
const gridW = 26, gridH = 34, _ox = 5, _oy = 9;

/// Linha dos pés na grade.
const feetRow = _oy + 21;

/// Cor da aura, com o ciclo de cores das formas cósmicas.
Color auraOf(Transformation f, int tick) =>
    f.cosmic ? Color(hslToArgb(((tick * 3) % 360).toDouble(), .75, .65)) : Color(f.auraColor);

typedef _R = void Function(int x, int y, int w, int h, Color? c);

(PixelGrid, _R) _canvas() {
  final g = List.generate(gridH, (_) => List<Color?>.filled(gridW, null));
  void r(int x, int y, int rw, int rh, Color? c) {
    for (var j = y + _oy; j < y + _oy + rh; j++) {
      for (var i = x + _ox; i < x + _ox + rw; i++) {
        if (j >= 0 && j < gridH && i >= 0 && i < gridW) g[j][i] = c;
      }
    }
  }

  return (g, r);
}

const _gray = Color(0xFF737AA2), _dark = Color(0xFF2F334D);

/// O dev de moletom: os fones chegam no nível 2, o notebook no 5 e os
/// óculos escuros de quem enxerga a Matrix no 7. Cores e aura mudam a cada
/// nível.
PixelGrid devGrid(Transformation f, {bool blink = false, int tick = 0}) {
  final (g, r) = _canvas();
  final aura = auraOf(f, tick);
  final top = f.cosmic ? Color.lerp(Color(f.suit), aura, .35)! : Color(f.suit);
  final acc = f.cosmic ? aura : Color(f.trim);
  final shade = Color.lerp(top, _ink, .25)!;
  final low = Color(f.pants), lowShade = Color.lerp(low, _ink, .25)!;
  final eye = blink ? _skinDark : _ink;
  // cabeça
  r(4, 1, 8, 2, _hair);
  r(3, 2, 10, 2, _hair);
  r(4, 3, 8, 6, _skin);
  r(4, 3, 8, 1, _hair);
  r(3, 4, 1, 3, _hair);
  r(12, 4, 1, 3, _hair);
  r(3, 5, 1, 2, _skin);
  r(12, 5, 1, 2, _skin);
  r(6, 5, 1, 1, eye);
  r(9, 5, 1, 1, eye);
  r(7, 7, 2, 1, _skinDark);
  r(7, 9, 2, 1, _skinDark);
  // moletom com capuz, braços e pernas
  r(3, 9, 10, 1, top);
  r(4, 10, 8, 6, top);
  r(4, 10, 8, 1, acc);
  r(2, 10, 2, 5, top);
  r(12, 10, 2, 5, top);
  r(2, 14, 2, 1, shade);
  r(12, 14, 2, 1, shade);
  r(2, 15, 2, 1, _skin);
  r(12, 15, 2, 1, _skin);
  r(6, 11, 1, 2, Px.fujiWhite);
  r(9, 11, 1, 2, Px.fujiWhite);
  r(5, 14, 6, 1, shade);
  r(4, 16, 3, 5, low);
  r(9, 16, 3, 5, low);
  r(4, 16, 8, 1, lowShade);
  r(7, 16, 2, 1, null);
  r(3, 21, 4, 1, Px.fujiWhite);
  r(9, 21, 4, 1, Px.fujiWhite);
  if (f.gear != Gear.none) {
    // fones de ouvido
    r(4, 0, 8, 1, _dark);
    r(3, 1, 1, 2, _dark);
    r(12, 1, 1, 2, _dark);
    r(2, 3, 2, 3, acc);
    r(12, 3, 2, 3, acc);
  }
  if (f.gear == Gear.jet) {
    // notebook aberto com código
    r(13, 10, 4, 5, _gray);
    r(14, 11, 2, 3, Px.sumiInk0);
    r(14, 11, 1, 1, acc);
    r(15, 12, 1, 1, const Color(0xFF4FD6BE));
    r(14, 13, 2, 1, acc);
    r(12, 15, 5, 1, _gray);
  }
  if (f.shades) {
    r(5, 5, 2, 1, _ink);
    r(9, 5, 2, 1, _ink);
    r(7, 5, 2, 1, _ink);
    r(5, 5, 1, 1, const Color(0xFF4FD6BE));
  }
  return outlined(g);
}

final _grids = <String, PixelGrid>{};

/// Grade do dev no nível [f].
PixelGrid characterGrid(Transformation f, {bool blink = false, int tick = 0}) {
  final t = f.cosmic ? tick ~/ 4 * 4 : 0;
  final key = '${f.index}|$blink|$t';
  if (_grids.length > 40) _grids.clear();
  return _grids[key] ??= devGrid(f, blink: blink, tick: t);
}

/// Caixa da figura (do capacete aos pés, com folga para a aura) com a grade em
/// [origin] e escala [sc].
Rect figureBox(Offset origin, double sc) =>
    Rect.fromLTWH(origin.dx + 7 * sc, origin.dy + (_oy - 5) * sc, 12 * sc, 27 * sc);

/// Força da aura.
int auraLevel(Transformation f) => f.aura;

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
    p.color = Color.lerp(c, Px.fujiWhite, .5)!.withAlpha((40 * pulse).round());
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
  p.color = Color.lerp(c, Px.fujiWhite, .4)!;
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
    ..color = (tick ~/ 4).isEven ? Px.lightBlue : Px.fujiWhite
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
