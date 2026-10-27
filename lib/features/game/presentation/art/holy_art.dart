import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/places.dart';

/// Quadro das cenas: 200 x 150, com o chão na linha 138.
const frameW = 200.0, frameH = 150.0, groundY = 138.0;

const _ink = Kanagawa.sumiInk0;
const _gold = Color(0xFFFFD84A);
const _wood = Color(0xFF8A6A3A);
const _darkWood = Color(0xFF5C4630);
const _stone = Color(0xFFC8B590);
const _cream = Color(0xFFE4D5B0);
const _white = Color(0xFFF4F0E8);
const _skin = Color(0xFFE8B48A);

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

void _circle(Canvas canvas, Paint p, double x, double y, double r, Color c) {
  p.color = c;
  canvas.drawCircle(Offset(x, y), r, p);
}

void _gradient(Canvas canvas, Rect r, Color top, Color bottom) => canvas.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])
          .createShader(r));

/// Céu do Caminho ao Céu e dos Céus, de dia ([day] = 1) ou de noite.
/// (Na Terra Santa a cena usa o céu de verdade, com o tempo de Bauru.)
void paintHolySky(Canvas canvas, Region region, double day, int tick) {
  const full = Rect.fromLTWH(0, 0, frameW, frameH);
  final heaven = region == Region.heaven;
  final top = Color.lerp(heaven ? const Color(0xFF2E2350) : const Color(0xFF1F1D3A),
      heaven ? const Color(0xFFEFC16A) : const Color(0xFFF2B8A0), day)!;
  final bottom = Color.lerp(heaven ? const Color(0xFF6A4E7E) : const Color(0xFF4A3F78),
      heaven ? const Color(0xFFFFF3D6) : const Color(0xFFFFE8C8), day)!;
  _gradient(canvas, full, top, bottom);
  final p = Paint();
  // estrelas à noite
  final night = 1 - day;
  if (night > .3) {
    for (var i = 0; i < 60; i++) {
      final tw = .6 + .4 * math.sin(tick * .08 + i * 1.9);
      _rect(canvas, p, ((i * 53 + 11) % 200).toDouble(), ((i * 31 + i * i) % 110).toDouble(), i % 7 == 0 ? 2 : 1,
          i % 7 == 0 ? 2 : 1, (i % 3 == 0 ? _gold : Kanagawa.fujiWhite).withAlpha((night * 230 * tw).round()));
    }
  }
  // luz vinda do alto
  for (var j = 0; j < 4; j++) {
    final a = (heaven ? 30 : 18) + 10 * math.sin(tick * .03 + j);
    p.color = const Color(0xFFFFF1C4).withAlpha(a.round());
    final x = 40.0 + j * 42;
    canvas.drawPath(
        Path()
          ..moveTo(x - 4, 0)
          ..lineTo(x + 4, 0)
          ..lineTo(x + 26, frameH)
          ..lineTo(x + 6, frameH)
          ..close(),
        p);
  }
}

/// Mar de nuvens embaixo (Caminho ao Céu e Céus).
void _cloudFloor(Canvas canvas, Paint p, double night, int tick, {required bool gold}) {
  final base = Color.lerp(gold ? const Color(0xFFFFF4D6) : Kanagawa.fujiWhite, const Color(0xFF8C82B0), night * .7)!;
  final shade = Color.lerp(base, gold ? const Color(0xFFE6C384) : const Color(0xFFD27E99), .35)!;
  for (var row = 0; row < 3; row++) {
    final y = 128.0 + row * 7;
    for (var i = 0; i < 11; i++) {
      final x = (i * 23 + row * 11 + tick * (.05 + row * .03)) % 260 - 30;
      _circle(canvas, p, x, y + 4, 8 + (i % 3) * 2.0, shade);
      _circle(canvas, p, x, y + 2, 7 + (i % 3) * 2.0, base);
    }
  }
  if (gold) {
    _gradient(canvas, const Rect.fromLTWH(0, groundY, frameW, frameH - groundY), const Color(0xFFFFE08A),
        const Color(0xFFE6B450));
    _rect(canvas, p, 0, groundY, frameW, 1, const Color(0xFFFFF6D8));
    for (var i = 0; i < 6; i++) {
      _rect(canvas, p, (i * 37 + tick * .2) % frameW, groundY + 3 + (i % 3) * 3, 8, 1, const Color(0xAAFFF6D8));
    }
  }
}

/// Colinas ao longe e chão de terra (Terra Santa).
void _landBackdrop(Canvas canvas, Paint p, double night, Color Function(Color) shade) {
  for (var x = 0; x < frameW; x++) {
    final h = 16 + 7 * math.sin(x * .045 + 1) + 4 * math.sin(x * .11);
    _rect(canvas, p, x.toDouble(), groundY - h, 1, h, shade(const Color(0xFF7D8A5E)));
  }
  for (var x = 0; x < frameW; x++) {
    final h = 7 + 4 * math.sin(x * .07 + 3);
    _rect(canvas, p, x.toDouble(), groundY - h, 1, h, shade(const Color(0xFF9A9A62)));
  }
  _rect(canvas, p, 0, groundY, frameW, frameH - groundY, shade(const Color(0xFFC9A66B)));
  _rect(canvas, p, 0, groundY, frameW, 1, shade(const Color(0xFFB08E58)));
  for (var x = 6.0; x < frameW; x += 23) {
    _rect(canvas, p, x, groundY + 5 + (x % 3), 3, 1, shade(const Color(0xFFB08E58)));
  }
}

/// Paisagem e marco do lugar no quadro 200 x 150, com o marco centrado em
/// [cx]. [night] escurece as cores da Terra Santa e acende as janelas.
void paintPlace(Canvas canvas, Place place, {double night = 0, int tick = 0, double cx = 165}) {
  final p = Paint();
  Color shade(Color c) => Color.lerp(c, _ink, night * .55)!;
  void rect(double x, double y, double w, double h, Color c) => _rect(canvas, p, cx + x, groundY + y, w, h, shade(c));
  void tri(double x, double baseW, double h, Color c, [double y = 0]) =>
      _tri(canvas, p, cx + x, groundY + y, baseW, h, shade(c));
  void circle(double x, double y, double r, Color c) => _circle(canvas, p, cx + x, groundY + y, r, shade(c));
  void glow(double x, double y, double r, Color c, [int alpha = 60]) {
    for (var k = 3; k >= 1; k--) {
      _circle(canvas, p, cx + x, groundY + y, r * k / 3 + r * .3, c.withAlpha(alpha ~/ k));
    }
  }

  final lit = night > .5 ? Kanagawa.carpYellow : const Color(0xFF3A2E22);
  if (place.region == Region.land) {
    _landBackdrop(canvas, p, night, shade);
  } else {
    _cloudFloor(canvas, p, place.region == Region.heaven ? night * .6 : night, tick,
        gold: place.region == Region.heaven);
  }

  switch (place.scene) {
    case Scene.manger:
      rect(-20, -28, 40, 28, _darkWood);
      rect(-23, -30, 3, 30, _wood);
      rect(20, -30, 3, 30, _wood);
      tri(0, 56, 13, const Color(0xFFB8924F), -28);
      rect(-20, -4, 40, 4, const Color(0xFFE6C384));
      glow(0, -12, 14, _gold, 70);
      rect(-9, -11, 18, 2, _wood);
      rect(-8, -9, 2, 6, _wood);
      rect(6, -9, 2, 6, _wood);
      rect(-8, -12, 16, 1, const Color(0xFFE6C384));
      rect(-4, -15, 9, 3, _white);
      rect(-6, -15, 3, 3, _skin);
      // estrela de Belém
      final sy = -68.0, tw = (tick ~/ 10).isEven ? 1.0 : 0.0;
      p.color = const Color(0xFFFFF1C4).withAlpha(30);
      canvas.drawPath(
          Path()
            ..moveTo(cx - 2, groundY + sy)
            ..lineTo(cx + 2, groundY + sy)
            ..lineTo(cx + 16, groundY - 28)
            ..lineTo(cx - 16, groundY - 28)
            ..close(),
          p);
      glow(0, sy, 6, _gold, 90);
      rect(-1, sy - 6 - tw, 2, 13 + tw * 2, Kanagawa.fujiWhite);
      rect(-6 - tw, sy - 1, 13 + tw * 2, 2, Kanagawa.fujiWhite);
      rect(-3, sy - 3, 6, 6, _gold);
    case Scene.village:
      for (final (x, w, h) in [(-38.0, 18.0, 16.0), (-15.0, 22.0, 24.0), (12.0, 20.0, 15.0)]) {
        rect(x, -h, w, h, _cream);
        rect(x - 1, -h - 2, w + 2, 2, _stone);
        rect(x + w / 2 - 2, -7, 4, 7, const Color(0xFF3A2E22));
        rect(x + 3, -h + 4, 3, 3, lit);
        if (w > 20) rect(x + w - 6, -h + 4, 3, 3, lit);
      }
      rect(36, -30, 2, 30, _wood);
      for (final (dx, dy, w) in [(-8.0, -32.0, 9.0), (1.0, -32.0, 9.0), (-6.0, -35.0, 6.0), (2.0, -35.0, 6.0)]) {
        rect(36 + dx, dy, w, 2, const Color(0xFF5E8049));
      }
      rect(35, -36, 4, 3, const Color(0xFF6F9655));
    case Scene.river:
      _rect(canvas, p, 64, groundY - 2, frameW - 64, 10, shade(const Color(0xFF4A90B8)));
      for (var i = 0; i < 12; i++) {
        final x = 66 + (i * 23 + tick * .4) % (frameW - 70);
        _rect(canvas, p, x, groundY + (i % 3) * 3, 6, 1, shade(const Color(0xFFA3D4E5)));
      }
      for (var i = 0; i < 9; i++) {
        _rect(canvas, p, 64.0 + i * 3, groundY - 6 - (i % 3) * 3, 1, 8 + (i % 3) * 3, shade(const Color(0xFF6F9655)));
      }
      // o céu se abre e o Espírito desce como pomba
      p.color = const Color(0xFFFFF1C4).withAlpha(40);
      canvas.drawPath(
          Path()
            ..moveTo(cx - 6, 0)
            ..lineTo(cx + 6, 0)
            ..lineTo(cx + 22, groundY)
            ..lineTo(cx - 22, groundY)
            ..close(),
          p);
      _dove(canvas, p, cx - 9, groundY - 62 + math.sin(tick * .06) * 2, 2, tick, branch: false);
    case Scene.sea:
      _rect(canvas, p, 72, groundY - 24, frameW - 72, 24, shade(const Color(0xFF3E7CB1)));
      for (var i = 0; i < 16; i++) {
        final x = 74 + (i * 19 + tick * .3) % (frameW - 78);
        _rect(canvas, p, x, groundY - 22 + (i % 5) * 4, 5, 1, shade(const Color(0xFF7FB4CA)));
      }
      final by = (math.sin(tick * .07) * 1.5).roundToDouble();
      rect(-16, -12 + by, 32, 3, _wood);
      rect(-13, -9 + by, 26, 2, _darkWood);
      rect(-1, -40 + by, 2, 28, _darkWood);
      for (var i = 0; i < 22; i++) {
        rect(1, -38 + i + by, 2 + i * .6, 1, _white);
      }
    case Scene.mount:
      tri(0, 130, 46, const Color(0xFF5E8049));
      tri(0, 74, 30, const Color(0xFF6F9655));
      final r = math.Random(7);
      for (var i = 0; i < 26; i++) {
        final x = -52 + r.nextDouble() * 104, y = -2 - r.nextDouble() * (40 - x.abs() * .7).clamp(2, 40);
        rect(x, y, 1, 1, [Kanagawa.autumnRed, _gold, Kanagawa.fujiWhite][i % 3]);
      }
      for (var i = 0; i < 7; i++) {
        final x = -40.0 + i * 12, y = -4 - (36 - x.abs() * .65).clamp(0, 30) * .5;
        rect(x, y - 4, 3, 4, [const Color(0xFF7E9CD8), _cream, Kanagawa.autumnRed, const Color(0xFF98BB6C)][i % 4]);
        rect(x + .5, y - 6, 2, 2, _skin);
      }
      rect(-1, -48, 3, 6, _white);
      rect(-.5, -50, 2, 2, _skin);
    case Scene.jars:
      for (var i = 0; i < 8; i++) {
        rect(-42.0 + i * 11, -44 + (i % 2) * 2, 6, 4, [Kanagawa.autumnRed, _gold, const Color(0xFF7E9CD8)][i % 3]);
      }
      rect(-44, -45, 88, 1, _darkWood);
      for (var i = 0; i < 6; i++) {
        final x = -33.0 + i * 11;
        rect(x, -13, 9, 12, const Color(0xFFB8B09A));
        rect(x + 6, -13, 2, 12, const Color(0xFF9A927C));
        rect(x + 2, -15, 5, 2, const Color(0xFFB8B09A));
        rect(x + 1, -16, 7, 1, const Color(0xFFA8A08A));
        rect(x + 2, -16, 5, 1, const Color(0xFF8E2A3B));
      }
    case Scene.city:
      rect(-16, -48, 32, 24, _cream);
      for (var i = 0; i < 5; i++) {
        rect(-13.0 + i * 6, -44, 2, 20, _stone);
      }
      circle(0, -50, 10, _gold);
      rect(-10, -50, 20, 2, const Color(0xFFE6C384));
      rect(-44, -26, 88, 26, _stone);
      for (var i = 0; i < 15; i++) {
        rect(-44.0 + i * 6, -29, 3, 3, _stone);
      }
      for (var y = -22.0; y < 0; y += 6) {
        rect(-44, y, 88, 1, const Color(0xFFB09C74));
      }
      rect(-6, -16, 12, 16, const Color(0xFF3A2E22));
      circle(0, -16, 6, const Color(0xFF3A2E22));
    case Scene.garden:
      for (final x in [-34.0, -2.0, 28.0]) {
        rect(x - 1, -14, 3, 14, const Color(0xFF6B5638));
        rect(x + 1, -18, 2, 5, const Color(0xFF6B5638));
        circle(x, -26, 10, const Color(0xFF6E7F5E));
        circle(x - 7, -21, 7, const Color(0xFF7A8B6A));
        circle(x + 7, -21, 7, const Color(0xFF7A8B6A));
        circle(x - 2, -29, 4, const Color(0xFF94A584));
      }
      glow(-16, -8, 10, const Color(0xFFFFF1C4), 50);
      rect(-24, -6, 16, 6, const Color(0xFF8A877A));
      rect(-22, -7, 12, 1, const Color(0xFF9A978A));
    case Scene.crosses:
      tri(0, 112, 26, const Color(0xFF6B5A44));
      glow(0, -50, 16, _gold, 60);
      rect(-1.5, -60, 3, 36, _darkWood);
      rect(-11, -52, 22, 3, _darkWood);
      for (final x in [-30.0, 30.0]) {
        rect(x - 1, -38, 2, 26, _darkWood);
        rect(x - 7, -33, 14, 2, _darkWood);
      }
    case Scene.tomb:
      circle(6, 2, 32, const Color(0xFF7A766A));
      circle(10, -2, 24, const Color(0xFF8A867A));
      glow(-2, -10, 14, _gold, 90);
      rect(-8, -16, 12, 16, const Color(0xFFFFE9A8));
      circle(-2, -16, 6, const Color(0xFFFFE9A8));
      for (var i = 0; i < 5; i++) {
        p.color = const Color(0xFFFFF1C4).withAlpha(60);
        final a = -math.pi * (.15 + i * .17);
        canvas.drawLine(Offset(cx - 2, groundY - 10),
            Offset(cx - 2 + math.cos(a) * 34, groundY - 10 + math.sin(a) * 34), p..strokeWidth = 2);
      }
      circle(-26, -11, 11, const Color(0xFF9A958A));
      circle(-26, -11, 7, const Color(0xFF8A857A));
    case Scene.road:
      for (var y = 0.0; y < 42; y++) {
        final t = y / 42;
        final w = 46 * (1 - t) + 3;
        final x = -6 + 18 * math.sin(t * 3.2);
        rect(x - w / 2, 11 - y, w, 1, const Color(0xFFD9C08A));
      }
      for (final x in [-40.0, -28.0, 30.0, 42.0]) {
        rect(x - 2, -26, 4, 26, const Color(0xFF3F5F4A));
        rect(x - 1, -30, 2, 4, const Color(0xFF3F5F4A));
      }
      rect(-9, -14, 2, 4, _cream);
      rect(-6, -14, 2, 4, const Color(0xFF7E9CD8));
    case Scene.ascension:
      tri(0, 120, 24, const Color(0xFF6F9655));
      p.color = const Color(0xFFFFF1C4).withAlpha(50);
      canvas.drawPath(
          Path()
            ..moveTo(cx - 10, 0)
            ..lineTo(cx + 10, 0)
            ..lineTo(cx + 18, groundY - 56)
            ..lineTo(cx - 18, groundY - 56)
            ..close(),
          p);
      for (final (x, y, r) in [(-12.0, -54.0, 9.0), (0.0, -58.0, 11.0), (13.0, -54.0, 9.0), (0.0, -50.0, 9.0)]) {
        circle(x, y, r, Kanagawa.fujiWhite);
      }
    case Scene.flames:
      rect(-24, -40, 48, 40, const Color(0xFFD8C8A0));
      rect(-26, -42, 52, 2, _stone);
      rect(-24, -22, 48, 2, const Color(0xFFB8A880));
      rect(-16, -34, 8, 8, _gold);
      rect(8, -34, 8, 8, _gold);
      rect(-4, -14, 8, 14, const Color(0xFF3A2E22));
      for (var k = -2; k <= 2; k++) {
        final h = 6.0 + (tick ~/ 4 + k * 3) % 4;
        final x = k * 9.0;
        rect(x - 2, -45 - h, 4, h, Kanagawa.surimiOrange);
        rect(x - 1, -44 - h + 2, 2, h - 2, _gold);
        rect(x - .5, -47 - h, 1, 2, Kanagawa.surimiOrange);
      }
    case Scene.clouds:
      for (final (x, y) in [(-30.0, -58.0), (20.0, -40.0), (-4.0, -24.0)]) {
        final dx = math.sin(tick * .02 + x) * 3;
        circle(x + dx, y, 9, Kanagawa.fujiWhite);
        circle(x + dx + 9, y + 2, 7, Kanagawa.fujiWhite);
        circle(x + dx - 9, y + 2, 6, Kanagawa.fujiWhite);
      }
    case Scene.ladder:
      glow(10, -128, 34, const Color(0xFFFFF1C4), 120);
      p
        ..color = _gold
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx - 14, groundY + 4), Offset(cx + 2, 0), p);
      canvas.drawLine(Offset(cx + 2, groundY + 4), Offset(cx + 18, 0), p);
      for (var y = groundY; y > 0; y -= 9) {
        final t = (groundY + 4 - y) / (groundY + 4);
        canvas.drawLine(Offset(cx - 14 + 16 * t, y), Offset(cx + 2 + 16 * t, y), p..strokeWidth = 1.5);
      }
      for (var k = 0; k < 3; k++) {
        final t = ((tick * .002 + k / 3) % 1);
        final y = groundY - t * groundY, x = cx - 6 + 16 * t;
        _rect(canvas, p, x - 1, y - 4, 3, 4, Kanagawa.fujiWhite);
        _rect(canvas, p, x - 4, y - 4, 2, 2, Kanagawa.fujiWhite.withAlpha(200));
        _rect(canvas, p, x + 3, y - 4, 2, 2, Kanagawa.fujiWhite.withAlpha(200));
        _rect(canvas, p, x - 1, y - 6, 3, 2, _skin);
      }
    case Scene.rainbow:
      const colors = [
        Color(0xFFE46876),
        Color(0xFFFFA066),
        Color(0xFFFFD84A),
        Color(0xFF98BB6C),
        Color(0xFF7FB4CA),
        Color(0xFF957FB8),
      ];
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;
      for (var i = 0; i < colors.length; i++) {
        p.color = colors[i].withAlpha(220);
        final r = 56.0 - i * 3;
        canvas.drawArc(Rect.fromCircle(center: Offset(cx - 10, groundY - 4), radius: r), math.pi, math.pi, false, p);
      }
      p.style = PaintingStyle.fill;
    case Scene.dove:
      glow(0, -50, 18, const Color(0xFFFFF1C4), 70);
      _dove(canvas, p, cx - 12, groundY - 60 + math.sin(tick * .06) * 3, 3, tick, branch: true);
    case Scene.pillar:
      final col = Rect.fromLTWH(cx - 14, 0, 28, groundY);
      canvas.drawRect(
          col,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55FFA066), Color(0xCCFFD84A)],
            ).createShader(col));
      _rect(canvas, p, cx - 5, 0, 10, groundY, const Color(0xAAFFF6D8));
      for (var i = 0; i < 14; i++) {
        final y = (i * 37 - tick * 1.2) % groundY;
        _rect(canvas, p, cx - 12 + (i * 7) % 24, y, 2, 3, _gold.withAlpha(200));
      }
    case Scene.gates:
      rect(-62, -30, 30, 30, const Color(0xFF8FB8A0));
      rect(32, -30, 30, 30, const Color(0xFF8FB8A0));
      for (var y = -26.0; y < 0; y += 6) {
        rect(-62, y, 30, 1, const Color(0xFF7AA38B));
        rect(32, y, 30, 1, const Color(0xFF7AA38B));
      }
      glow(0, -24, 22, _gold, 90);
      rect(-11, -44, 22, 44, const Color(0xFFFFE9A8));
      circle(0, -44, 11, const Color(0xFFFFE9A8));
      rect(-22, -44, 10, 44, _white);
      rect(12, -44, 10, 44, _white);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = shade(_white);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, groundY - 44), radius: 16), math.pi, math.pi, false, p);
      p.style = PaintingStyle.fill;
      circle(0, -62, 4, Kanagawa.fujiWhite);
      rect(-2, -64, 1, 1, _gold);
    case Scene.street:
      for (var y = 0.0; y < 40; y++) {
        final t = y / 40;
        final w = 110 * (1 - t) + 6;
        rect(-8 - w / 2, 11 - y, w, 1, Color.lerp(_gold, const Color(0xFFFFF1C4), t)!);
      }
      for (final (x, w, h, c) in [
        (-58.0, 16.0, 34.0, const Color(0xFF4FA88A)),
        (-42.0, 12.0, 24.0, const Color(0xFF5A7FD0)),
        (26.0, 12.0, 26.0, const Color(0xFF9A6AC0)),
        (38.0, 16.0, 38.0, const Color(0xFFD06A6A)),
      ]) {
        rect(x, -h, w, h, c);
        rect(x, -h - 1, w, 2, _gold);
        rect(x + w / 2 - 2, -h + 6, 4, 6, const Color(0xFFFFF6D8));
      }
    case Scene.lifeRiver:
      rect(-70, -20, 140, 20, const Color(0xFF98BB6C));
      for (var y = 0.0; y < 32; y++) {
        final t = y / 32;
        final w = 60 * (1 - t) + 4;
        rect(-4 - w / 2, 11 - y, w, 1, Color.lerp(const Color(0xFFA3D4E5), Kanagawa.fujiWhite, t * .6)!);
      }
      for (var i = 0; i < 10; i++) {
        final t = ((i * .1 + tick * .004) % 1);
        rect(-4 + (i % 3 - 1) * 20 * (1 - t), -20 + t * 30, 2, 1, Kanagawa.fujiWhite);
      }
      for (final x in [-50.0, 44.0]) {
        rect(x - 1, -30, 3, 10, const Color(0xFF7A5A3A));
        circle(x, -34, 8, const Color(0xFF5E8A4A));
      }
    case Scene.tree:
      rect(-30, -4, 60, 4, const Color(0xFFA3D4E5));
      rect(-5, -32, 10, 32, const Color(0xFF7A5A3A));
      rect(-9, -4, 4, 4, const Color(0xFF7A5A3A));
      rect(5, -4, 4, 4, const Color(0xFF7A5A3A));
      circle(0, -44, 20, const Color(0xFF4F8A4A));
      circle(-17, -36, 13, const Color(0xFF4F8A4A));
      circle(17, -36, 13, const Color(0xFF4F8A4A));
      circle(-4, -50, 9, const Color(0xFF6FA860));
      const fruits = [
        Color(0xFFE46876),
        Color(0xFFFFA066),
        Color(0xFFFFD84A),
        Color(0xFF957FB8),
        Color(0xFF7FB4CA),
        Color(0xFFD27E99),
      ];
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi * 2 / 12;
        rect(math.cos(a) * 18 - 1, -40 + math.sin(a) * 12 - 1, 3, 3, fruits[i % fruits.length]);
      }
    case Scene.throne:
      glow(0, -30, 30, Kanagawa.fujiWhite, 130);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xB498BB6C);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, groundY - 28), width: 76, height: 56), p);
      p.style = PaintingStyle.fill;
      rect(-30, -6, 60, 6, _white);
      rect(-22, -12, 44, 6, Kanagawa.fujiWhite);
      rect(-12, -28, 24, 16, _gold);
      rect(-10, -46, 20, 18, _gold);
      rect(-7, -43, 14, 12, const Color(0xFFFFF1C4));
      rect(-1, -50, 2, 4, _gold);
  }
}

/// Pomba branca voando, com [s] pixels por ponto.
void _dove(Canvas canvas, Paint p, double x, double y, double s, int tick, {required bool branch}) {
  final up = (tick ~/ 8).isEven;
  void px(double dx, double dy, double w, double h, Color c) =>
      _rect(canvas, p, x + dx * s, y + dy * s, w * s, h * s, c);
  px(2, 3, 6, 2, Kanagawa.fujiWhite);
  px(7, 2, 2, 2, Kanagawa.fujiWhite);
  px(9, 3, 1, 1, Kanagawa.surimiOrange);
  px(8, 2, 1, 1, _ink);
  px(0, 3, 2, 1, Kanagawa.fujiWhite);
  if (up) {
    px(3, 0, 3, 3, Kanagawa.fujiWhite);
    px(4, -1, 2, 1, Kanagawa.fujiWhite);
  } else {
    px(3, 5, 3, 2, Kanagawa.fujiWhite);
  }
  if (branch) {
    px(10, 3, 3, 1, const Color(0xFF6F9655));
    px(11, 2, 1, 1, const Color(0xFF98BB6C));
    px(12, 4, 1, 1, const Color(0xFF98BB6C));
  }
}

/// Miniatura de um lugar num quadro [size] (mapa e avisos).
void paintPlaceThumb(Canvas canvas, Place d, Size size, int tick) {
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  final s = math.max(size.width / frameW, size.height / frameH);
  canvas.translate((size.width - frameW * s) / 2, size.height - frameH * s);
  canvas.scale(s);
  if (d.region == Region.land) {
    _gradient(canvas, const Rect.fromLTWH(0, 0, frameW, frameH), const Color(0xFF3E7CB1), const Color(0xFFA3D4E5));
  } else {
    paintHolySky(canvas, d.region, 1, tick);
  }
  paintPlace(canvas, d, tick: tick, cx: frameW / 2);
  canvas.restore();
}

/// Pomba subindo rumo à luz (tela de carregamento), num quadro 160x90.
void paintAscend(Canvas canvas, double progress, int tick) {
  const r = Rect.fromLTWH(0, 0, 160, 90);
  _gradient(canvas, r, Color.lerp(const Color(0xFF1F1D3A), const Color(0xFFFFE9B0), progress)!,
      Color.lerp(const Color(0xFF4A3F78), const Color(0xFFFFF8E6), progress)!);
  final p = Paint();
  for (var i = 0; i < 6; i++) {
    final y = (i * 19 + progress * 260) % 110 - 10;
    _circle(canvas, p, (i * 41 % 160).toDouble(), y, 9, Kanagawa.fujiWhite.withAlpha(170));
    _circle(canvas, p, (i * 41 % 160) + 9.0, y + 2, 6, Kanagawa.fujiWhite.withAlpha(170));
  }
  _circle(canvas, p, 80, 6, 18 + 6 * progress, const Color(0xFFFFF1C4).withAlpha((60 + 120 * progress).round()));
  _dove(canvas, p, 64, 62 - progress * 34 + math.sin(tick * .5) * 1.5, 3, tick, branch: true);
}
