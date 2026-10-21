import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';

/// Cena animada: o astronauta flutua sobre o destino atual, com a nave
/// pousada, o próximo destino ao longe e a energia que cresce com o nível.
class SpaceScene extends ConsumerStatefulWidget {
  const SpaceScene({super.key});

  @override
  ConsumerState<SpaceScene> createState() => _SpaceSceneState();
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color, [this.text]);
  double x, y, vx, vy;
  double life;
  final double size;
  final Color color;
  final String? text;
}

class _SpaceSceneState extends ConsumerState<SpaceScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rand = math.Random();
  final _aura = <_Particle>[];
  final _bursts = <_Particle>[];
  late final List<(double, double, double, int)> _stars;
  int _tick = 0;
  int _jump = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(70, (i) {
      return (((i * 53 + 7) % 200).toDouble(), ((i * 29 + i * i) % 128).toDouble(), i % 9 == 0 ? 2.0 : 1.0, i % 3 + 1);
    });
    _ticker = createTicker((_) {
      if (!mounted) return;
      setState(_step);
    })
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion && _ticker.isActive) _ticker.stop();
    if (!_reduceMotion && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _step() {
    _tick++;
    if (_jump > 0) _jump--;
    final stats = ref.read(statsProvider);
    final mode = ref.read(gameControllerProvider).suitMode;
    final lv = stats.lv;
    final rate = 1 + math.min(12, lv ~/ 4) + mode * 2;
    for (var i = 0; i < rate; i++) {
      if (_rand.nextDouble() > 0.6) continue;
      final a = _rand.nextDouble() * math.pi * 2;
      final rr = 16 + math.min(30, lv * 0.6) + mode * 6;
      _aura.add(_Particle(100 + math.cos(a) * rr * 0.7, 58 + math.sin(a) * rr, -math.cos(a) * 0.2,
          -math.sin(a) * 0.2 - 0.15, 25 + _rand.nextDouble() * 25, _rand.nextDouble() < 0.3 ? 2 : 1, Colors.white));
    }
    if (_aura.length > 300) _aura.removeRange(0, _aura.length - 300);
    for (final p in _aura) {
      p
        ..life -= 1
        ..x += p.vx
        ..y += p.vy;
    }
    _aura.removeWhere((p) => p.life <= 0);
    if (mode >= 3 && _tick % 3 == 0) {
      _bursts.add(_Particle(100 + (_rand.nextDouble() - .5) * 40, 30 + _rand.nextDouble() * 50, 0, -.3, 30, 1,
          Kanagawa.carpYellow));
    }
    for (final p in _bursts) {
      p
        ..life -= 1
        ..x += p.vx
        ..y += p.vy
        ..vy += p.text == null ? 0.04 : 0;
    }
    _bursts.removeWhere((p) => p.life <= 0);
  }

  void _celebrate(int xp) {
    _jump = 26;
    for (var i = 0; i < 16; i++) {
      _bursts.add(_Particle(100, 50, (_rand.nextDouble() - .5) * 3, -_rand.nextDouble() * 2 - 1, 40, 2,
          i.isEven ? Kanagawa.fujiWhite : Kanagawa.carpYellow));
    }
    if (xp > 0) _bursts.add(_Particle(74, 28, 0, -.5, 50, 0, Kanagawa.springBlue, '+$xp XP'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(burstProvider, (_, next) {
      if (next != null) _celebrate(next.xp);
    });
    final state = ref.watch(gameControllerProvider);
    final stats = ref.watch(statsProvider);
    final mode = suitModes[state.suitMode];
    final auraColor = state.suitMode > 0 ? Color(mode.color) : Color(stats.rank.color);

    return Semantics(
      label: 'Guilherme Fuentes, astronauta mirim, em ${stats.destination.name}',
      child: AspectRatio(
        aspectRatio: 200 / 128,
        child: CustomPaint(
          painter: _ScenePainter(
            tick: _tick,
            jump: _jump,
            stars: _stars,
            aura: _aura,
            bursts: _bursts,
            auraColor: auraColor,
            level: stats.lv,
            mode: state.suitMode,
            rank: stats.rankIndex,
            mk: stats.suitMk,
            equipped: state.equipped,
            here: stats.destination,
            next: stats.nextDestination,
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.tick,
    required this.jump,
    required this.stars,
    required this.aura,
    required this.bursts,
    required this.auraColor,
    required this.level,
    required this.mode,
    required this.rank,
    required this.mk,
    required this.equipped,
    required this.here,
    required this.next,
  });

  final int tick;
  final int jump;
  final List<(double, double, double, int)> stars;
  final List<_Particle> aura;
  final List<_Particle> bursts;
  final Color auraColor;
  final int level;
  final int mode;
  final int rank;
  final int mk;
  final Map<String, String> equipped;
  final Destination here;
  final Destination next;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 128);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 200, 128));
    final p = Paint();

    p.color = Kanagawa.sumiInk0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 128), p);
    const nebula = [Kanagawa.oniViolet, Kanagawa.crystalBlue, Kanagawa.sakuraPink];
    for (var i = 0; i < 6; i++) {
      p.color = nebula[i % 3].withAlpha(20);
      canvas.drawCircle(Offset(((i * 61) % 200).toDouble(), ((i * 37) % 70).toDouble()), 18.0 + (i % 3) * 8, p);
    }
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      if (((tick >> 3) + i) % 23 == 0) continue;
      final x = (s.$1 - tick * 0.02 * s.$4) % 200;
      p.color = i % 5 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
      canvas.drawRect(Rect.fromLTWH(x.floorToDouble(), s.$2, s.$3, s.$3), p);
    }

    paintBody(canvas, next, const Offset(170, 24), 9, tick);
    _label(canvas, next.name, const Offset(170, 36), 5, Kanagawa.fujiWhite, center: true);
    paintBody(canvas, here, const Offset(100, 214), 112, tick);
    _ship(canvas, p);

    final intensity = math.min(1.0, .15 + level / 30 + mode * .15);
    p.color = auraColor.withAlpha(((.10 + .12 * intensity) * 255).round());
    canvas.drawCircle(const Offset(100, 58), 18.0 + math.min(26, level * .5) + mode * 5, p);
    if (mode >= 2) {
      final shield = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Kanagawa.springBlue.withAlpha(((.5 + .2 * math.sin(tick * .08)) * 255).round());
      canvas.drawCircle(const Offset(100, 58), 30, shield);
    }
    for (final a in aura) {
      final alpha = (math.min(1.0, a.life / 30) * (.4 + intensity * .6)).clamp(0.0, 1.0);
      p.color = auraColor.withAlpha((alpha * 255).round());
      canvas.drawRect(Rect.fromLTWH(a.x.roundToDouble(), a.y.roundToDouble(), a.size, a.size), p);
    }

    final bob = jump > 0 ? -(math.sin(jump / 26 * math.pi) * 10).roundToDouble() : (math.sin(tick * .04) * 3).roundToDouble();
    const scale = 2.1;
    final origin = Offset(100 - 13 * scale, 24 + bob);
    final flame = (mode >= 1 ? 7 : 4) + (tick >> 2) % 3;
    for (final fx in [6.0, 18.0]) {
      p.color = Kanagawa.surimiOrange;
      canvas.drawRect(Rect.fromLTWH(origin.dx + (fx + .5) * scale, origin.dy + 20 * scale, 2 * scale, flame.toDouble()), p);
      p.color = Kanagawa.carpYellow;
      canvas.drawRect(Rect.fromLTWH(origin.dx + (fx + 1) * scale, origin.dy + 20 * scale, scale, math.max(2, flame - 3).toDouble()), p);
    }
    final blink = tick % 200 < 6;
    paintGrid(canvas, astronautGrid(rank: rank, mk: mk, equipped: equipped, blink: blink), origin, scale);

    final pet = equipped['pet'];
    if (pet != null) paintPet(canvas, pet, Offset(134, 48 + (math.sin(tick * .05) * 3).roundToDouble()));
    if (equipped['satellite'] != null) {
      final a = tick * .03;
      paintPet(canvas, 'sat', Offset((96 + math.cos(a) * 42).roundToDouble(), (56 + math.sin(a) * 18).roundToDouble()));
    }

    p.color = Kanagawa.sumiInk0;
    canvas.drawRect(const Rect.fromLTWH(4, 4, 92, 13), p);
    p.color = Kanagawa.sumiInk4;
    canvas.drawRect(const Rect.fromLTWH(5, 5, 90, 11), p);
    _label(canvas, here.name.toUpperCase(), const Offset(8, 7.5), 5, Kanagawa.carpYellow, maxChars: 14);

    for (final b in bursts) {
      if (b.text != null) {
        _label(canvas, b.text!, Offset(b.x, b.y), 7, b.color);
      } else {
        p.color = b.color;
        canvas.drawRect(Rect.fromLTWH(b.x.roundToDouble(), b.y.roundToDouble(), b.size, b.size), p);
      }
    }
    canvas.restore();
  }

  void _ship(Canvas canvas, Paint p) {
    const sx = 30.0, sy = 82.0;
    void r(double a, double b, double w, double h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(sx + a, sy + b, w, h), p);
    }

    r(4, -14, 8, 26, Kanagawa.sumiInk0);
    r(5, -13, 6, 24, Kanagawa.fujiWhite);
    r(6, -17, 4, 4, Kanagawa.sumiInk0);
    r(6, -16, 4, 3, Kanagawa.autumnRed);
    r(6, -6, 4, 4, Kanagawa.waveBlue1);
    r(7, -5, 2, 2, Kanagawa.springBlue);
    r(0, 4, 5, 8, Kanagawa.autumnRed);
    r(11, 4, 5, 8, Kanagawa.autumnRed);
    r(5, 11, 6, 2, Kanagawa.fujiGray);
  }

  void _label(Canvas canvas, String text, Offset at, double size, Color color,
      {bool center = false, int maxChars = 16}) {
    final t = text.length > maxChars ? text.substring(0, maxChars) : text;
    final tp = TextPainter(
      text: TextSpan(text: t, style: PixelText.display(size, color: color).copyWith(height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}
