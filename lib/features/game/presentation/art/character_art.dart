import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart' show hslToArgb;
import '../../domain/catalog/transformations.dart';
import 'pixel_art.dart';

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _ink = Kanagawa.sumiInk0;

/// Grade dos personagens: 26 x 31, com a figura entre as colunas 6 e 20
/// e os pés na linha 27 (há espaço em cima para o cabelo espetado).
const gridW = 26, gridH = 31, _ox = 5, _oy = 6;

/// Linha dos pés na grade.
const feetRow = 27;

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

/// Pessoa (na Terra): roupa e cabelo mudam com a transformação.
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
  if (f.hair == Hair.normal) {
    r(4, 0, 8, 2, hair);
    r(4, 2, 1, 3, hair);
    r(11, 2, 1, 2, hair);
    r(5, 2, 3, 1, hair);
  } else {
    _spikes(r, hair);
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
    case Outfit.training:
      const hoodie = Color(0xFF727169), pants = Color(0xFF1F1F28);
      r(4, 10, 8, 6, hoodie);
      r(2, 10, 2, 5, hoodie);
      r(12, 10, 2, 5, hoodie);
      r(4, 13, 8, 1, Kanagawa.autumnRed);
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
      r(7, 10, 2, 2, blue);
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
  }
  return outlined(g);
}

/// Astronauta: o traje ganha as cores da transformação e o cabelo
/// aparece pelo visor.
PixelGrid astronautGrid(Transformation f, {bool blink = false, int tick = 0}) {
  final (g, r) = _canvas();
  final aura = auraOf(f, tick), hair = hairOf(f, tick);
  final suit = Color.lerp(const Color(0xFFE4DFC6), aura, f.aura > 0 ? .28 : 0)!;
  final shade = Color.lerp(suit, _ink, .2)!;
  final accent = f.aura >= 2 ? aura : Kanagawa.surimiOrange;
  final visor = f.hair == Hair.normal ? Kanagawa.waveBlue1 : Color.lerp(Kanagawa.waveBlue1, hair, .35)!;
  final eyes = Color(f.eyes);
  // tanques
  r(1, 11, 2, 6, Kanagawa.fujiGray);
  r(13, 11, 2, 6, Kanagawa.fujiGray);
  r(1, 16, 2, 1, Kanagawa.sumiInk6);
  r(13, 16, 2, 1, Kanagawa.sumiInk6);
  if (f.outfit == Outfit.giCape || f.outfit == Outfit.divine) {
    r(3, 10, 10, 11, f.outfit == Outfit.divine ? const Color(0xFF7E9CD8) : Kanagawa.autumnRed);
  }
  // capacete
  r(5, 0, 6, 1, Kanagawa.fujiWhite);
  r(4, 1, 8, 1, Kanagawa.fujiWhite);
  r(3, 2, 10, 7, Kanagawa.fujiWhite);
  r(4, 9, 8, 1, Kanagawa.oldWhite);
  r(3, 8, 10, 1, Kanagawa.oldWhite);
  if (f.aura >= 2) r(3, 2, 1, 6, accent);
  // visor e rosto
  r(4, 3, 8, 5, visor);
  r(5, 4, 6, 3, _skin);
  r(5, 4, 6, 1, hair);
  r(5, 5, 1, 1, hair);
  if (f.hair != Hair.normal) {
    r(7, 4, 1, 1, hair);
    r(10, 4, 1, 2, hair);
  }
  r(6, 5, 1, 1, blink ? _skinDark : eyes);
  r(9, 5, 1, 1, blink ? _skinDark : eyes);
  r(7, 6, 2, 1, _skinDark);
  r(10, 3, 1, 1, Kanagawa.lightBlue);
  r(11, 4, 1, 1, Kanagawa.lightBlue);
  // corpo
  r(4, 10, 8, 6, suit);
  r(4, 15, 8, 1, accent);
  r(6, 11, 4, 2, _ink);
  r(6, 11, 1, 1, Kanagawa.autumnRed);
  r(7, 11, 1, 1, Kanagawa.springGreen);
  r(8, 11, 1, 1, Kanagawa.springBlue);
  r(9, 12, 1, 1, Kanagawa.carpYellow);
  r(5, 13, 3, 2, const Color(0xFF3F8F4A));
  r(6, 13, 1, 2, const Color(0xFFE6C384));
  // braços
  r(2, 10, 2, 5, suit);
  r(12, 10, 2, 5, suit);
  r(2, 14, 2, 1, shade);
  r(12, 14, 2, 1, shade);
  r(2, 15, 2, 1, accent);
  r(12, 15, 2, 1, accent);
  // pernas
  r(4, 16, 3, 5, suit);
  r(9, 16, 3, 5, suit);
  r(4, 18, 3, 1, shade);
  r(9, 18, 3, 1, shade);
  r(4, 20, 3, 1, _ink);
  r(9, 20, 3, 1, _ink);
  r(4, 21, 3, 1, accent);
  r(9, 21, 3, 1, accent);
  return outlined(g);
}

final _grids = <String, PixelGrid>{};

/// Grade do personagem (pessoa ou astronauta) na transformação [f].
PixelGrid characterGrid(Transformation f, {required bool astronaut, bool blink = false, int tick = 0}) {
  final t = f.cosmic ? tick ~/ 4 * 4 : 0;
  final key = '${f.index}|$astronaut|$blink|$t';
  if (_grids.length > 40) _grids.clear();
  return _grids[key] ??= astronaut ? astronautGrid(f, blink: blink, tick: t) : personGrid(f, blink: blink, tick: t);
}

/// Caixa ocupada pela figura com a grade em [origin] e escala [sc].
Rect figureBox(Offset origin, double sc) => Rect.fromLTWH(origin.dx + 7 * sc, origin.dy + 1 * sc, 12 * sc, 27 * sc);

class AuraParticle {
  AuraParticle(this.x, this.y, this.vx, this.vy, this.life, this.size);
  double x, y, vx, vy, life;
  final double size;
}

/// Chamas da aura subindo em volta de [box].
void stepAura(List<AuraParticle> list, Rect box, Transformation f, math.Random rand) {
  final n = const [0, 1, 3, 5][f.aura.clamp(0, 3)];
  for (var i = 0; i < n; i++) {
    final side = rand.nextBool();
    final x = side
        ? box.left + rand.nextDouble() * box.width * .3 - box.width * .08
        : box.right - rand.nextDouble() * box.width * .3 + box.width * .08;
    final y = box.top + box.height * (.15 + rand.nextDouble() * .85);
    list.add(AuraParticle(
        x,
        y,
        (side ? -.08 : .08) * rand.nextDouble(),
        -(.5 + rand.nextDouble() * .7) * (1 + f.aura * .3),
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
  if (list.length > 260) list.removeRange(0, list.length - 260);
}

/// Brilho e chamas atrás do personagem.
void paintAuraBack(Canvas canvas, Rect box, Transformation f, List<AuraParticle> list, int tick) {
  if (f.aura <= 0) return;
  final c = auraOf(f, tick);
  final p = Paint();
  final pulse = .85 + .15 * math.sin(tick * .15);
  p.color = c.withAlpha((28 * f.aura * pulse).round());
  canvas.drawOval(Rect.fromCenter(center: box.center, width: box.width * 2.1, height: box.height * 1.35), p);
  p.color = c.withAlpha((34 * f.aura * pulse).round());
  canvas.drawOval(
      Rect.fromCenter(
          center: box.center.translate(0, box.height * .05), width: box.width * 1.5, height: box.height * 1.15),
      p);
  if (f.aura >= 2) {
    // contorno de chama
    final h = box.height * (1.18 + .04 * math.sin(tick * .3));
    final w = box.width * 1.7;
    final path = Path()
      ..moveTo(box.center.dx - w / 2, box.bottom)
      ..quadraticBezierTo(box.center.dx - w * .62, box.bottom - h * .55, box.center.dx - w * .12, box.bottom - h)
      ..lineTo(box.center.dx, box.bottom - h * .9)
      ..lineTo(box.center.dx + w * .12, box.bottom - h)
      ..quadraticBezierTo(box.center.dx + w * .62, box.bottom - h * .55, box.center.dx + w / 2, box.bottom)
      ..close();
    p.color = c.withAlpha((60 * pulse).round());
    canvas.drawPath(path, p);
  }
  for (final a in list) {
    p.color = c.withAlpha((math.min(1.0, a.life / 14) * 230).round());
    canvas.drawRect(Rect.fromLTWH(a.x.roundToDouble(), a.y.roundToDouble(), a.size, a.size * 1.6), p);
  }
}

/// Raios na frente do personagem.
void paintAuraFront(Canvas canvas, Rect box, Transformation f, int tick) {
  if (!f.lightning || tick % 9 > 3) return;
  final r = math.Random(tick ~/ 4);
  final p = Paint()
    ..color = (tick ~/ 4).isEven ? Kanagawa.lightBlue : Kanagawa.fujiWhite
    ..strokeWidth = math.max(1, box.width / 22)
    ..style = PaintingStyle.stroke;
  for (var k = 0; k < 2; k++) {
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
