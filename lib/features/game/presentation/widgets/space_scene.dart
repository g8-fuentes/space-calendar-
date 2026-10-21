import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color, [this.text]);
  double x, y, vx, vy, life;
  final double size;
  final Color color;
  final String? text;
}

/// Cena animada: o astronauta flutua sobre o destino atual, encarando o
/// inimigo do nível, com a nave pousada e o próximo destino ao longe.
class SpaceScene extends ConsumerStatefulWidget {
  const SpaceScene({super.key});

  @override
  ConsumerState<SpaceScene> createState() => _SpaceSceneState();
}

class _SpaceSceneState extends ConsumerState<SpaceScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rand = math.Random();
  final _aura = <_Particle>[];
  final _bursts = <_Particle>[];
  final _magic = <_Particle>[];
  final _stars = List.generate(
      70, (i) => [((i * 53 + 7) % 200).toDouble(), ((i * 29 + i * i) % 128).toDouble(), i % 9 == 0 ? 2.0 : 1.0, (i % 3 + 1).toDouble()]);
  int _tick = 0, _jump = 0, _shake = 0, _lastFrame = -1;

  @override
  void initState() {
    super.initState();
    // Pixel art de baixa resolução: 30 quadros por segundo bastam.
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      final frame = elapsed.inMilliseconds ~/ 33;
      if (frame == _lastFrame) return;
      final steps = _lastFrame < 0 ? 1 : (frame - _lastFrame).clamp(1, 3);
      _lastFrame = frame;
      setState(() {
        for (var i = 0; i < steps; i++) {
          _step();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) {
      _lastFrame = -1;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static const ax = 70.0, ay = 58.0;

  void _step() {
    _tick++;
    if (_jump > 0) _jump--;
    if (_shake > 0) _shake--;
    final stats = ref.read(statsProvider);
    final s = ref.read(gameControllerProvider);
    final lv = stats.lv, mode = s.suitMode;
    final rate = 1 + math.min(12, lv ~/ 4) + mode * 2;
    for (var i = 0; i < rate; i++) {
      if (_rand.nextDouble() > .6) continue;
      final a = _rand.nextDouble() * math.pi * 2;
      final rr = 16 + math.min(30, lv * .6) + mode * 6;
      _aura.add(_Particle(ax + math.cos(a) * rr * .7, ay + math.sin(a) * rr, -math.cos(a) * .2,
          -math.sin(a) * .2 - .15, 25 + _rand.nextDouble() * 25, _rand.nextDouble() < .3 ? 2 : 1, Colors.white));
    }
    if (_aura.length > 300) _aura.removeRange(0, _aura.length - 300);
    final magic = s.equipped['magic'];
    final mc = magic == null ? null : shopItem(magic);
    if (mc != null) {
      final c = Color(mc.color!);
      if (magic == 'mg_star' && _tick % 5 == 0) {
        _magic.add(_Particle(_rand.nextDouble() * 200, -2, -.3, .8, 160, _rand.nextDouble() < .3 ? 2 : 1, c));
      } else if (magic == 'mg_fire' && _tick.isEven) {
        _magic.add(_Particle(ax + (_rand.nextDouble() - .5) * 34, ay + 26, 0, -.5 - _rand.nextDouble() * .4, 40, 2,
            _rand.nextBool() ? c : Kanagawa.lightBlue));
      } else if (magic == 'mg_comet' && _tick.isEven) {
        _magic.add(_Particle(ax - 8 + (_rand.nextDouble() - .5) * 6, ay + (_rand.nextDouble() - .5) * 14,
            -1.1 - _rand.nextDouble(), 0, 35, 2, _rand.nextBool() ? c : Kanagawa.carpYellow));
      }
    }
    if (_magic.length > 200) _magic.removeRange(0, _magic.length - 200);
    if (mode >= 3 && _tick % 3 == 0) {
      _bursts.add(_Particle(ax + (_rand.nextDouble() - .5) * 40, 30 + _rand.nextDouble() * 50, 0, -.3, 30, 1, Kanagawa.carpYellow));
    }
    for (final list in [_aura, _magic, _bursts]) {
      for (final p in list) {
        p
          ..life -= 1
          ..x += p.vx
          ..y += p.vy;
        if (identical(list, _bursts) && p.text == null) p.vy += .04;
      }
      list.removeWhere((p) => p.life <= 0 || p.y > 132);
    }
  }

  void _celebrate(int xp) {
    _jump = 26;
    _shake = 14;
    for (var i = 0; i < 16; i++) {
      _bursts.add(_Particle(ax, 50, (_rand.nextDouble() - .5) * 3, -_rand.nextDouble() * 2 - 1, 40, 2,
          i.isEven ? Kanagawa.fujiWhite : Kanagawa.carpYellow));
    }
    if (xp > 0) _bursts.add(_Particle(46, 26, 0, -.5, 50, 0, Kanagawa.springBlue, '+$xp XP'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(burstProvider, (_, next) {
      if (next != null) _celebrate(next.xp);
    });
    final s = ref.watch(gameControllerProvider);
    final stats = ref.watch(statsProvider);
    final auraColor = Color(s.suitMode > 0 ? suitModes[s.suitMode].color : stats.rank.color);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final hour = now.hour + now.minute / 60;
    return Semantics(
      label: 'Astronauta em ${stats.destination.name}, diante de ${stats.enemy.name}, '
          '${skyAt(hour).day > .5 ? 'com o sol no céu' : 'sob a lua e as estrelas'}',
      child: RepaintBoundary(
        child: AspectRatio(
          aspectRatio: 200 / 128,
          child: CustomPaint(
            painter: _ScenePainter(
              tick: _tick,
              jump: _jump,
              shake: _shake,
              stars: _stars,
              aura: _aura,
              magic: _magic,
              bursts: _bursts,
              auraColor: auraColor,
              level: stats.lv,
              mode: s.suitMode,
              rank: stats.rankIndex,
              mk: stats.suitMk,
              equipped: s.equipped,
              here: stats.destination,
              next: stats.nextDestination,
              enemy: stats.enemy,
              hour: hour,
            ),
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
    required this.shake,
    required this.stars,
    required this.aura,
    required this.magic,
    required this.bursts,
    required this.auraColor,
    required this.level,
    required this.mode,
    required this.rank,
    required this.mk,
    required this.equipped,
    required this.here,
    required this.next,
    required this.enemy,
    required this.hour,
  });

  final int tick, jump, shake, level, mode, rank, mk;
  final double hour;
  final List<List<double>> stars;
  final List<_Particle> aura, magic, bursts;
  final Color auraColor;
  final Map<String, String> equipped;
  final Destination here, next;
  final Enemy enemy;

  static const ax = _SpaceSceneState.ax, ay = _SpaceSceneState.ay;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 128);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 200, 128));
    final p = Paint();
    _sky(canvas, p);
    paintBody(canvas, next, const Offset(182, 16), 7, tick);
    paintBody(canvas, here, const Offset(100, 214), 112, tick);
    _ship(canvas, p);

    // inimigo do nível
    final fs = enemy.boss ? 2.4 : 2.5, fN = enemy.size * fs;
    final fx = 148 - fN / 2 + (shake > 0 ? ((tick % 4) < 2 ? -2 : 2) : 0);
    final fy = 46 - fN / 2 + (math.sin(tick * .05 + 1) * 3).roundToDouble();
    p.color = Color(enemy.color).withAlpha(38);
    canvas.drawCircle(Offset(148, 46 + fN / 2 + 8), fN * .45, p);
    paintGrid(canvas, enemyGrid(enemy), Offset(fx, fy), fs);
    _label(canvas, 'NV $level', Offset(148, fy + fN + 4), 5, Kanagawa.waveRed, center: true);

    // magia (portal atrás)
    final magicId = equipped['magic'];
    final magicItem = magicId == null ? null : shopItem(magicId);
    if (magicId == 'mg_portal' && magicItem != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color(magicItem.color!).withAlpha(((.55 + .25 * math.sin(tick * .06)) * 255).round());
      canvas.drawOval(Rect.fromCenter(center: const Offset(ax, ay), width: (22 + math.sin(tick * .05) * 2) * 2, height: 64), stroke);
      stroke
        ..strokeWidth = 1
        ..color = Kanagawa.lightBlue.withAlpha(140);
      canvas.drawOval(Rect.fromCenter(center: const Offset(ax, ay), width: 34, height: 52), stroke);
    }

    // aura
    final intensity = math.min(1.0, .15 + level / 30 + mode * .15);
    p.color = auraColor.withAlpha(((.10 + .12 * intensity) * 255).round());
    canvas.drawCircle(const Offset(ax, ay), 18.0 + math.min(26, level * .5) + mode * 5, p);
    if (mode >= 2) {
      canvas.drawCircle(
          const Offset(ax, ay),
          30,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Kanagawa.springBlue.withAlpha(((.5 + .2 * math.sin(tick * .08)) * 255).round()));
    }
    for (final a in aura) {
      final alpha = (math.min(1.0, a.life / 30) * (.4 + intensity * .6)).clamp(0.0, 1.0);
      p.color = auraColor.withAlpha((alpha * 255).round());
      canvas.drawRect(Rect.fromLTWH(a.x.roundToDouble(), a.y.roundToDouble(), a.size, a.size), p);
    }

    // astronauta
    final bob = jump > 0 ? -(math.sin(jump / 26 * math.pi) * 10).roundToDouble() : (math.sin(tick * .04) * 3).roundToDouble();
    const sc = 2.1;
    final origin = Offset(ax - 13 * sc, 24 + bob);
    final flame = (mode >= 1 ? 7 : 4) + (tick >> 2) % 3;
    for (final fx2 in [6.0, 18.0]) {
      p.color = Kanagawa.surimiOrange;
      canvas.drawRect(Rect.fromLTWH(origin.dx + (fx2 + .5) * sc, origin.dy + 20 * sc, 2 * sc, flame.toDouble()), p);
      p.color = Kanagawa.carpYellow;
      canvas.drawRect(Rect.fromLTWH(origin.dx + (fx2 + 1) * sc, origin.dy + 20 * sc, sc, math.max(2, flame - 3).toDouble()), p);
    }
    paintGrid(canvas, _astronaut(rank, mk, equipped, tick % 200 < 6, tick), origin, sc);

    if (magicItem != null) {
      final c = Color(magicItem.color!);
      if (magicId == 'mg_arc') {
        for (var i = 0; i < 5; i++) {
          final a = tick * .03 + i * 1.2566;
          final x = (ax + math.cos(a) * 30).roundToDouble(), y = (ay + math.sin(a) * 14).roundToDouble();
          p.color = i.isOdd ? c : Kanagawa.sakuraPink;
          canvas.drawRect(Rect.fromLTWH(x - 1, y, 3, 1), p);
          canvas.drawRect(Rect.fromLTWH(x, y - 1, 1, 3), p);
        }
      } else if (magicId == 'mg_halo') {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(ax, origin.dy - 4), width: 22, height: 6),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = c.withAlpha(((.7 + .3 * math.sin(tick * .1)).clamp(0.0, 1.0) * 255).round()));
      }
    }
    for (final m in magic) {
      p.color = m.color.withAlpha((math.min(1.0, m.life / 20) * 255).round());
      canvas.drawRect(Rect.fromLTWH(m.x.roundToDouble(), m.y.roundToDouble(), m.size, m.size), p);
    }
    final pet = equipped['pet'];
    if (pet != null) paintPet(canvas, pet, Offset(ax - 46, 52 + (math.sin(tick * .05) * 3).roundToDouble()), tick);
    if (equipped['orbit'] != null) {
      final a = tick * .03;
      paintPet(canvas, 'sat', Offset((ax - 6 + math.cos(a) * 36).roundToDouble(), (ay - 4 + math.sin(a) * 16).roundToDouble()), tick);
    }

    // placa do destino
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

  /// Céu conforme a hora do celular: de dia o sol cruza a cena e as
  /// estrelas quase somem; à noite a lua aparece e as estrelas brilham.
  void _sky(Canvas canvas, Paint p) {
    final sky = skyAt(hour);
    const full = Rect.fromLTWH(0, 0, 200, 128);
    p.color = Kanagawa.sumiInk0;
    canvas.drawRect(full, p);
    if (sky.day > 0) {
      canvas.drawRect(
          full,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Kanagawa.waveBlue1.withAlpha((sky.day * 255).round()),
                Kanagawa.waveBlue2.withAlpha((sky.day * 255).round()),
              ],
            ).createShader(full));
    }
    if (sky.dusk > 0) {
      canvas.drawRect(
          full,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Kanagawa.oniViolet.withAlpha(0),
                Kanagawa.sakuraPink.withAlpha((sky.dusk * 70).round()),
                Kanagawa.surimiOrange.withAlpha((sky.dusk * 120).round()),
              ],
            ).createShader(full));
    }
    const nebula = [Kanagawa.oniViolet, Kanagawa.crystalBlue, Kanagawa.sakuraPink];
    for (var i = 0; i < 6; i++) {
      p.color = nebula[i % 3].withAlpha((20 + 14 * sky.night).round());
      canvas.drawCircle(Offset(((i * 61) % 200).toDouble(), ((i * 37) % 70).toDouble()), 18.0 + (i % 3) * 8, p);
    }
    for (var i = 0; i < stars.length; i++) {
      if (((tick >> 3) + i) % 23 == 0) continue;
      // De dia só um terço das estrelas aparece, bem fraco.
      if (sky.day > .5 && i % 3 != 0) continue;
      final s = stars[i];
      final x = ((s[0] - tick * .02 * s[3]) % 200).floorToDouble();
      final twinkle = .75 + .25 * math.sin(tick * .09 + i * 1.7);
      final alpha = (255 * (.3 + .7 * sky.night) * (sky.night > .5 ? twinkle : 1)).round().clamp(0, 255);
      final c = i % 5 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
      p.color = c.withAlpha(alpha);
      final size = s[2] + (sky.night > .5 && i % 4 == 0 ? 1 : 0);
      canvas.drawRect(Rect.fromLTWH(x, s[1], size, size), p);
      if (sky.night > .5 && i % 9 == 0) {
        // brilho em cruz nas estrelas grandes
        p.color = c.withAlpha((alpha * .6).round());
        canvas.drawRect(Rect.fromLTWH(x - 2, s[1] + size / 2 - .5, size + 4, 1), p);
        canvas.drawRect(Rect.fromLTWH(x + size / 2 - .5, s[1] - 2, 1, size + 4), p);
      }
    }
    final sun = sky.sun, moon = sky.moon;
    if (sun != null) _sun(canvas, p, sun);
    if (moon != null) _moon(canvas, p, moon);
  }

  void _sun(Canvas canvas, Paint p, Offset c) {
    p.color = Kanagawa.carpYellow.withAlpha(28);
    canvas.drawCircle(c, 20, p);
    p.color = Kanagawa.carpYellow.withAlpha(50);
    canvas.drawCircle(c, 13, p);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + tick * .01;
      final len = i.isEven ? 4.0 : 3.0;
      final r0 = 10.0 + ((tick >> 3) + i) % 2;
      p.color = Kanagawa.surimiOrange;
      for (var k = 0.0; k < len; k++) {
        canvas.drawRect(
            Rect.fromLTWH((c.dx + math.cos(a) * (r0 + k)).roundToDouble(), (c.dy + math.sin(a) * (r0 + k)).roundToDouble(), 1, 1), p);
      }
    }
    p.color = Kanagawa.surimiOrange;
    canvas.drawCircle(c, 8, p);
    p.color = Kanagawa.carpYellow;
    canvas.drawCircle(c, 7, p);
    p.color = const Color(0xFFFFF1C4);
    canvas.drawRect(Rect.fromLTWH(c.dx - 4, c.dy - 4, 3, 2), p);
  }

  void _moon(Canvas canvas, Paint p, Offset c) {
    p.color = Kanagawa.fujiWhite.withAlpha(22);
    canvas.drawCircle(c, 15, p);
    p.color = Kanagawa.fujiWhite.withAlpha(40);
    canvas.drawCircle(c, 10, p);
    // crescente: o disco menos um disco deslocado
    final lit = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: 7)),
      Path()..addOval(Rect.fromCircle(center: c.translate(4, -2), radius: 6)),
    );
    p.color = Kanagawa.fujiWhite;
    canvas.drawPath(lit, p);
    p.color = Kanagawa.fujiGray.withAlpha(150);
    for (final (dx, dy, w) in const [(-5.0, 0.0, 2.0), (-3.0, 3.0, 2.0), (-1.0, 5.0, 1.0)]) {
      canvas.drawRect(Rect.fromLTWH(c.dx + dx, c.dy + dy, w, w), p);
    }
  }

  void _ship(Canvas canvas, Paint p) {
    const sx = 4.0, sy = 86.0;
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

  static final _labels = <String, TextPainter>{};
  static final _grids = <String, PixelGrid>{};

  static PixelGrid _astronaut(int rank, int mk, Map<String, String> eq, bool blink, int tick) {
    // Só a skin Aurora e o sabre mudam com o tempo.
    final animated = eq['skin'] == 'sk_aur' || eq['hand'] == 'saber';
    final key = '$rank|$mk|$blink|${animated ? tick : 0}|${eq.entries.map((e) => '${e.key}=${e.value}').join(',')}';
    if (_grids.length > 24) _grids.clear();
    return _grids[key] ??= astronautGrid(rank: rank, mk: mk, equipped: eq, blink: blink, tick: tick);
  }

  void _label(Canvas canvas, String text, Offset at, double size, Color color, {bool center = false, int maxChars = 16}) {
    final t = text.length > maxChars ? text.substring(0, maxChars) : text;
    final key = '$t|$size|${color.toARGB32()}';
    final tp = _labels[key] ??= (TextPainter(
      text: TextSpan(text: t, style: PixelText.display(size, color: color).copyWith(height: 1)),
      textDirection: TextDirection.ltr,
    )..layout());
    if (_labels.length > 64) _labels.remove(_labels.keys.first);
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}

/// Cena da tela inicial: astronauta perto da Terra e o primeiro inimigo.
class IntroScene extends StatefulWidget {
  const IntroScene({super.key});

  @override
  State<IntroScene> createState() => _IntroSceneState();
}

class _IntroSceneState extends State<IntroScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    var last = -1;
    _ticker = createTicker((e) {
      final f = e.inMilliseconds ~/ 33;
      if (f != last && mounted) {
        last = f;
        setState(() => _tick++);
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AspectRatio(aspectRatio: 200 / 96, child: CustomPaint(painter: _IntroPainter(_tick))),
      );
}

class _IntroPainter extends CustomPainter {
  _IntroPainter(this.tick);
  final int tick;
  static final _astro = astronautGrid(rank: 0, mk: 1, equipped: const {});
  static final _blink = astronautGrid(rank: 0, mk: 1, equipped: const {}, blink: true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 96);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 200, 96));
    final p = Paint()..color = Kanagawa.sumiInk0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 96), p);
    for (var i = 0; i < 70; i++) {
      if (((tick >> 3) + i) % 19 == 0) continue;
      final l = i % 3 + 1, s = i % 9 == 0 ? 2.0 : 1.0;
      final x = ((((i * 53 + 7) % 200) + 200 - (tick * .05 * l) % 200) % 200).floorToDouble();
      p.color = i % 5 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
      canvas.drawRect(Rect.fromLTWH(x, (((i * 29 + i * i) % 128) % 96).toDouble(), s, s), p);
    }
    paintBody(canvas, destinationAt(0), const Offset(40, 120), 48, tick);
    paintBody(canvas, destinationAt(1), const Offset(170, 20), 8, tick);
    final bob = (math.sin(tick * .05) * 3).roundToDouble();
    paintGrid(canvas, tick % 180 < 6 ? _blink : _astro, Offset(100 - 13 * 1.8, 14 + bob), 1.8);
    paintGrid(canvas, enemyGrid(enemyFor(1)), Offset(158, 52 + (math.sin(tick * .05 + 2) * 2).roundToDouble()), 2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IntroPainter old) => old.tick != tick;
}

/// Luz do céu numa hora do dia (0 a 24).
class Sky {
  const Sky(this.day, this.dusk, this.sun, this.moon);

  /// 1 = dia claro, 0 = noite.
  final double day;

  /// Força do pôr/nascer do sol.
  final double dusk;
  final Offset? sun;
  final Offset? moon;

  double get night => 1 - day;
}

Sky skyAt(double h) {
  double ramp(double x, double a, double b) => ((x - a) / (b - a)).clamp(0.0, 1.0);
  final day = h < 12 ? ramp(h, 5, 7) : 1 - ramp(h, 17, 19);
  final dusk = math.max(0.0, 1 - math.min((h - 6).abs(), (h - 18).abs()) / 1.5);
  Offset arc(double t) => Offset(40 + t * 130, 40 - math.sin(math.pi * t) * 20);
  final sunT = (h - 6) / 12;
  final moonT = ((h - 18 + 24) % 24) / 12;
  return Sky(
    day,
    dusk,
    sunT >= -.04 && sunT <= 1.04 ? arc(sunT) : null,
    moonT >= -.04 && moonT <= 1.04 && day < 1 ? arc(moonT) : null,
  );
}
