import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/transformations.dart';
import 'pixel_art.dart';

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _hair = Color(0xFF2E1D14);
const _eyes = Color(0xFF16161D);
const _gold = Color(0xFFFFD84A);

/// Grade do personagem: 26 x 34, com a figura entre as colunas 6 e 20
/// e os pés na linha 30 (há espaço em cima para a auréola).
const gridW = 26, gridH = 34, _ox = 5, _oy = 9;

/// Linha dos pés na grade.
const feetRow = _oy + 21;

/// Cor da luz; nos níveis mais altos ela troca de tom devagar.
Color auraOf(Transformation f, int tick) {
  if (!f.shimmer) return Color(f.auraColor);
  const tones = [Color(0xFFFFE08A), Color(0xFFFFFFFF), Color(0xFFA3D4E5)];
  final t = tick / 60;
  final i = t.floor() % tones.length;
  return Color.lerp(tones[i], tones[(i + 1) % tones.length], t - t.floor())!;
}

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

/// Túnica longa até [hem], com mangas até a linha 14 e sandálias.
void _long(_R r, Color cloth, Color hemColor, int hem) {
  r(4, 10, 8, hem - 10, cloth);
  r(3, 16, 10, hem - 16, cloth);
  r(2, 10, 2, 5, cloth);
  r(12, 10, 2, 5, cloth);
  r(2, 15, 2, 1, _skin);
  r(12, 15, 2, 1, _skin);
  r(3, hem - 1, 10, 1, hemColor);
  r(4, hem, 3, 21 - hem, _skin);
  r(9, hem, 3, 21 - hem, _skin);
  r(3, 21, 4, 1, const Color(0xFF8A6A3A));
  r(9, 21, 4, 1, const Color(0xFF8A6A3A));
}

/// O personagem, um jovem adulto: a roupa fica mais clara a cada etapa.
PixelGrid personGrid(Transformation f, {bool blink = false}) {
  final (g, r) = _canvas();
  // cabeça
  r(5, 2, 6, 7, _skin);
  r(4, 5, 1, 2, _skin);
  r(11, 5, 1, 2, _skin);
  r(4, 0, 8, 2, _hair);
  r(4, 2, 1, 3, _hair);
  r(11, 2, 1, 2, _hair);
  r(5, 2, 3, 1, _hair);
  r(6, 5, 1, 1, blink ? _skinDark : _eyes);
  r(9, 5, 1, 1, blink ? _skinDark : _eyes);
  r(7, 7, 2, 1, _skinDark);
  r(7, 9, 2, 1, _skin);
  // roupa
  switch (f.outfit) {
    case Outfit.casual:
      const tee = Color(0xFF7E9CD8), jeans = Color(0xFF2D4F67);
      r(4, 10, 8, 6, tee);
      r(2, 10, 2, 2, tee);
      r(12, 10, 2, 2, tee);
      r(2, 12, 2, 4, _skin);
      r(12, 12, 2, 4, _skin);
      r(4, 16, 8, 1, jeans);
      r(4, 17, 3, 4, jeans);
      r(9, 17, 3, 4, jeans);
      r(3, 21, 4, 1, Kanagawa.fujiWhite);
      r(9, 21, 4, 1, Kanagawa.fujiWhite);
    case Outfit.shirt:
      const shirt = Color(0xFFE8E4D4), khaki = Color(0xFFB8A27A), shoes = Color(0xFF5C4630);
      r(4, 10, 8, 6, shirt);
      r(2, 10, 2, 4, shirt);
      r(12, 10, 2, 4, shirt);
      r(2, 14, 2, 2, _skin);
      r(12, 14, 2, 2, _skin);
      r(7, 10, 2, 1, _skin);
      r(6, 10, 1, 1, Kanagawa.fujiWhite);
      r(9, 10, 1, 1, Kanagawa.fujiWhite);
      r(8, 12, 1, 1, Kanagawa.fujiGray);
      r(8, 14, 1, 1, Kanagawa.fujiGray);
      r(4, 16, 8, 1, shoes);
      r(4, 17, 3, 4, khaki);
      r(9, 17, 3, 4, khaki);
      r(3, 21, 4, 1, shoes);
      r(9, 21, 4, 1, shoes);
    case Outfit.tunic:
      const tunic = Color(0xFFD8C8A0), rope = Color(0xFF8A6A3A);
      _long(r, tunic, Color.lerp(tunic, rope, .4)!, 19);
      r(7, 10, 2, 2, _skin);
      r(4, 14, 8, 1, rope);
      r(5, 15, 1, 1, rope);
    case Outfit.robe:
      const robe = Color(0xFFF0EDE0);
      _long(r, robe, _gold, 20);
      r(7, 10, 2, 1, _skin);
      r(4, 14, 8, 1, _gold);
      r(9, 15, 1, 2, _gold);
    case Outfit.radiant:
      const robe = Color(0xFFFFFDF4);
      _long(r, robe, _gold, 20);
      const mantle = Color(0xFF9CC4E4);
      r(2, 10, 2, 4, mantle);
      r(12, 10, 2, 4, mantle);
      r(4, 10, 1, 9, mantle);
      r(11, 10, 1, 9, mantle);
      r(7, 10, 2, 1, _skin);
      r(6, 10, 1, 1, _gold);
      r(9, 10, 1, 1, _gold);
      r(4, 14, 8, 1, _gold);
      r(9, 15, 1, 3, _gold);
      r(2, 14, 2, 1, _gold);
      r(12, 14, 2, 1, _gold);
  }
  return outlined(g);
}

final _grids = <String, PixelGrid>{};

/// Grade do personagem no nível [f].
PixelGrid characterGrid(Transformation f, {bool blink = false}) {
  final key = '${f.outfit.index}|$blink';
  return _grids[key] ??= personGrid(f, blink: blink);
}

/// Caixa ocupada pela figura (da cabeça aos pés) com a grade em [origin]
/// e escala [sc].
Rect figureBox(Offset origin, double sc) =>
    Rect.fromLTWH(origin.dx + 7 * sc, origin.dy + (_oy - 1) * sc, 12 * sc, 23 * sc);

/// Força da luz; acima das nuvens ele sempre tem pelo menos um brilho.
int auraLevel(Transformation f, {bool lifted = false}) => lifted ? math.max(1, f.aura) : f.aura;

class AuraParticle {
  AuraParticle(this.x, this.y, this.vx, this.vy, this.life, this.size);
  double x, y, vx, vy, life;
  final double size;
}

/// Partículas de luz subindo em volta de [box], com força [level].
void stepAura(List<AuraParticle> list, Rect box, Transformation f, int level, math.Random rand) {
  final rate = const [0.0, .3, 1.0, 2.0, 3.0, 4.0][level.clamp(0, 5)];
  var n = rate.floor();
  if (rand.nextDouble() < rate - n) n++;
  final spread = level >= 5 ? .5 : .25;
  for (var i = 0; i < n; i++) {
    final x = box.center.dx + (rand.nextDouble() - .5) * box.width * (1 + spread * 2);
    final y = box.top + box.height * (.2 + rand.nextDouble() * .8);
    list.add(AuraParticle(x, y, (rand.nextDouble() - .5) * .1, -(.25 + rand.nextDouble() * .45),
        30 + rand.nextDouble() * 30, rand.nextDouble() < .3 ? 2 : 1));
  }
  for (final p in list) {
    p
      ..life -= 1
      ..x += p.vx
      ..y += p.vy;
  }
  list.removeWhere((p) => p.life <= 0);
  if (list.length > 300) list.removeRange(0, list.length - 300);
}

/// Raios de luz descendo do alto até o personagem.
void _rays(Canvas canvas, Rect box, int tick) {
  final p = Paint();
  final top = box.top - box.height * 2;
  for (var j = 0; j < 5; j++) {
    final a = 18 + 14 * math.sin(tick * .05 + j * 1.3);
    p.color = const Color(0xFFFFF1C4).withAlpha(a.round().clamp(0, 255));
    final dx = (j - 2) * box.width * .28;
    final w0 = box.width * .06, w1 = box.width * (.22 + .04 * (j % 2));
    final x0 = box.center.dx + dx * .4, x1 = box.center.dx + dx;
    canvas.drawPath(
        Path()
          ..moveTo(x0 - w0, top)
          ..lineTo(x0 + w0, top)
          ..lineTo(x1 + w1, box.bottom)
          ..lineTo(x1 - w1, box.bottom)
          ..close(),
        p);
  }
}

/// Asa esquerda em pixels (G = borda dourada, W = luz); a direita é o
/// espelho.
const _wingMask = [
  '.......GGG.',
  '.....GGWWW.',
  '...GGWWWWWW',
  '..GWWWWWWWW',
  '.GWWWWWWWWW',
  'GWWWWWWWWWW',
  'GWWWGWWWWW.',
  '.GWWWGWWWW.',
  '..GWW.GWWW.',
  '...GW..WWW.',
  '....G...WW.',
  '........W..',
];

/// Asas de luz saindo dos ombros.
void _wings(Canvas canvas, Offset o, double sc, Color c, int tick) {
  final lift = (tick ~/ 24).isEven ? 0.0 : sc;
  final p = Paint();
  final w = _wingMask.first.length;
  for (var row = 0; row < _wingMask.length; row++) {
    final y = o.dy + (_oy + 4 + row) * sc - lift;
    for (var col = 0; col < w; col++) {
      final ch = _wingMask[row][col];
      if (ch == '.') continue;
      p.color = ch == 'G' ? c.withAlpha(235) : Kanagawa.fujiWhite.withAlpha(215);
      canvas.drawRect(Rect.fromLTWH(o.dx + (7 - w + col) * sc, y, sc, sc), p);
      canvas.drawRect(Rect.fromLTWH(o.dx + (19 + w - 1 - col) * sc, y, sc, sc), p);
    }
  }
}

void _star(Canvas canvas, Paint p, double x, double y, double s, Color c) {
  p.color = c;
  canvas.drawRect(Rect.fromLTWH(x - s, y, s * 3, s), p);
  canvas.drawRect(Rect.fromLTWH(x, y - s, s, s * 3), p);
}

void _ring(Canvas canvas, Rect box, int level, Color c, int tick, {required bool front}) {
  if (level < 4) return;
  final p = Paint();
  final n = level >= 5 ? 10 : 7;
  final s = math.max(1.0, (box.width / 14).roundToDouble());
  for (var i = 0; i < n; i++) {
    final ang = tick * .04 + i * 2 * math.pi / n;
    if ((math.sin(ang) > 0) != front) continue;
    final x = box.center.dx + math.cos(ang) * box.width * 1.1;
    final y = box.center.dy + box.height * .15 + math.sin(ang) * box.height * .1;
    _star(canvas, p, x.roundToDouble(), y.roundToDouble(), s, Color.lerp(c, Kanagawa.fujiWhite, .5)!);
  }
}

/// Luz atrás do personagem: raios do céu, asas, brilho e partículas.
/// [o] é o canto da grade e [sc] a escala.
void paintAuraBack(Canvas canvas, Offset o, double sc, Transformation f, int level, List<AuraParticle> list, int tick) {
  final box = figureBox(o, sc);
  final c = auraOf(f, tick);
  if (f.rays) _rays(canvas, box, tick);
  if (level > 0) {
    final p = Paint();
    final pulse = .85 + .15 * math.sin(tick * .1);
    final glow = math.min(level, 3);
    if (level >= 5) {
      p.color = c.withAlpha((30 * pulse).round());
      canvas.drawOval(Rect.fromCenter(center: box.center, width: box.width * 3.2, height: box.height * 1.7), p);
    }
    p.color = c.withAlpha((26 * glow * pulse).round());
    canvas.drawOval(Rect.fromCenter(center: box.center, width: box.width * 2.1, height: box.height * 1.35), p);
    p.color = c.withAlpha((30 * glow * pulse).round());
    canvas.drawOval(Rect.fromCenter(center: box.center, width: box.width * 1.5, height: box.height * 1.15), p);
    if (level >= 3) {
      // coluna de luz
      final col =
          Rect.fromLTRB(box.left + box.width * .1, box.top - box.height * .8, box.right - box.width * .1, box.bottom);
      canvas.drawRect(
          col,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.withAlpha(0), c.withAlpha((45 * pulse).round())],
            ).createShader(col));
    }
  }
  if (f.wings) _wings(canvas, o, sc, c, tick);
  _ring(canvas, box, level, c, tick, front: false);
  final p = Paint();
  for (final a in list) {
    p.color = (a.size > 1 ? Kanagawa.fujiWhite : c).withAlpha((math.min(1.0, a.life / 20) * 230).round());
    final s = a.size * math.max(1.0, sc / 3);
    canvas.drawRect(Rect.fromLTWH(a.x.roundToDouble(), a.y.roundToDouble(), s, s), p);
  }
}

/// Auréola e a frente do anel de estrelas.
void paintAuraFront(Canvas canvas, Offset o, double sc, Transformation f, int level, int tick) {
  final box = figureBox(o, sc);
  final c = auraOf(f, tick);
  _ring(canvas, box, level, c, tick, front: true);
  if (f.halo <= 0) return;
  final center = Offset(o.dx + 13 * sc, o.dy + (_oy - 1.8) * sc);
  final p = Paint()..style = PaintingStyle.stroke;
  if (f.halo >= 2) {
    p
      ..color = c.withAlpha(90)
      ..strokeWidth = sc * 1.6;
    canvas.drawOval(Rect.fromCenter(center: center, width: 8 * sc, height: 2.4 * sc), p);
  }
  p
    ..color = _gold
    ..strokeWidth = sc * .8;
  canvas.drawOval(Rect.fromCenter(center: center, width: 7 * sc, height: 1.8 * sc), p);
  p
    ..color = const Color(0xFFFFF6D8)
    ..strokeWidth = sc * .35;
  canvas.drawOval(Rect.fromCenter(center: center, width: 7 * sc, height: 1.8 * sc), p);
}

PixelGrid? _jesus;

/// Jesus: túnica branca, manto vermelho e braços abertos.
PixelGrid jesusGrid() => _jesus ??= () {
      final (g, r) = _canvas();
      const robe = Color(0xFFFFFDF4), mantle = Color(0xFFC34043), hair = Color(0xFF4A3020);
      // cabelo até os ombros e barba
      r(4, 0, 8, 2, hair);
      r(3, 2, 2, 8, hair);
      r(11, 2, 2, 8, hair);
      r(5, 2, 6, 6, _skin);
      r(5, 2, 6, 1, hair);
      r(6, 4, 1, 1, _eyes);
      r(9, 4, 1, 1, _eyes);
      r(5, 6, 1, 3, hair);
      r(10, 6, 1, 3, hair);
      r(6, 7, 4, 2, hair);
      r(7, 7, 2, 1, _skinDark);
      // túnica e braços abertos
      r(4, 10, 8, 11, robe);
      r(3, 15, 10, 6, robe);
      r(1, 10, 3, 3, robe);
      r(-1, 12, 3, 3, robe);
      r(-1, 15, 2, 1, _skin);
      r(12, 10, 3, 3, robe);
      r(14, 12, 3, 3, robe);
      r(15, 15, 2, 1, _skin);
      for (var k = 0; k < 5; k++) {
        r(4 + k * 2, 10 + k * 2, 2, 2, mantle);
      }
      r(5, 21, 2, 1, _skin);
      r(9, 21, 2, 1, _skin);
      return outlined(g);
    }();

/// Jesus com a luz em volta, de pés em [feet] e escala [sc].
void paintJesus(Canvas canvas, Offset feet, double sc, int tick) {
  final o = Offset(feet.dx - 13 * sc, feet.dy - (feetRow + 1) * sc);
  final box = figureBox(o, sc);
  final p = Paint();
  final pulse = .85 + .15 * math.sin(tick * .07);
  for (var k = 3; k >= 1; k--) {
    p.color = const Color(0xFFFFF1C4).withAlpha((38 * pulse).round());
    canvas.drawOval(
        Rect.fromCenter(center: box.center, width: box.width * (1 + k * .55), height: box.height * (1 + k * .2)), p);
  }
  paintGrid(canvas, jesusGrid(), o, sc);
  final halo = Offset(o.dx + 13 * sc, o.dy + (_oy - 1.6) * sc);
  p
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, sc * .8)
    ..color = _gold;
  canvas.drawOval(Rect.fromCenter(center: halo, width: 7 * sc, height: 1.8 * sc), p);
}
