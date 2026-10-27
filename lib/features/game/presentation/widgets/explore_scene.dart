import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../../../core/weather/weather.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/places.dart';
import '../../domain/catalog/transformations.dart';
import '../art/character_art.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';

/// Luz do dia numa hora (0 a 24): 1 = dia claro, 0 = noite.
double dayLight(double h) {
  double ramp(double x, double a, double b) => ((x - a) / (b - a)).clamp(0.0, 1.0);
  return h < 12 ? ramp(h, 5, 7) : 1 - ramp(h, 17, 19);
}

/// Força do nascer e do pôr do sol.
double duskLight(double h) => math.max(0.0, 1 - math.min((h - 6).abs(), (h - 18).abs()) / 1.5);

/// O sol aparece entre 6h e 18h; no resto do dia, a lua.
bool isSunUp(double h) => h >= 6 && h < 18;

class _Spark {
  _Spark(this.x, this.y, this.vx, this.vy, this.life, this.color, [this.text]);
  double x, y, vx, vy, life;
  final Color color;
  final String? text;
}

const sceneW = 200.0, sceneH = 150.0;

const _sc = 3.9;

/// Canto da grade do personagem na cena (sem pulo nem balanço): na Terra
/// fica em pé no chão; no espaço, voa com a aura.
Offset _originOf(bool earth) => Offset(56 - 13 * _sc, earth ? 138 - (feetRow + 1) * _sc : 132 - (feetRow + 1) * _sc);

/// Cena da exploração: o dev lutador grande no lugar atual, com a hora ao
/// lado, sol ou lua conforme o relógio e, na Terra, o tempo de Bauru.
/// Toque nele para ele pular.
class ExploreScene extends ConsumerStatefulWidget {
  const ExploreScene({super.key, this.placeOverride});

  /// Mostra este lugar em vez do atual (tela inicial).
  final Place? placeOverride;

  @override
  ConsumerState<ExploreScene> createState() => _ExploreSceneState();
}

class _ExploreSceneState extends ConsumerState<ExploreScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rand = math.Random();
  final _sparks = <_Spark>[];
  final _aura = <AuraParticle>[];
  Transformation _form = transformationAt(0);
  bool _earth = true;
  int _tick = 0, _jump = 0, _lastFrame = -1;

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

  void _step() {
    _tick++;
    if (_jump > 0) _jump--;
    for (final p in _sparks) {
      p
        ..life -= 1
        ..x += p.vx
        ..y += p.vy;
      if (p.text == null) p.vy += .05;
    }
    _sparks.removeWhere((p) => p.life <= 0 || p.y > sceneH);
    stepAura(_aura, figureBox(_originOf(_earth), _sc), _form, auraLevel(_form, space: !_earth), _rand);
  }

  void _celebrate({bool text = true}) {
    _jump = 26;
    for (var i = 0; i < 18; i++) {
      _sparks.add(_Spark(58, 70, (_rand.nextDouble() - .5) * 3.4, -_rand.nextDouble() * 2.4 - 1, 40,
          i.isEven ? Kanagawa.fujiWhite : Kanagawa.carpYellow));
    }
    if (text) _sparks.add(_Spark(40, 50, 0, -.45, 55, Kanagawa.springGreen, '+1 MISSÃO'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(burstProvider, (_, next) {
      if (next != null) _celebrate();
    });
    final stats = ref.watch(statsProvider);
    final place = widget.placeOverride ?? stats.place;
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final weather = place.region == Region.earth ? ref.watch(weatherProvider).valueOrNull : null;
    _form = stats.form;
    _earth = place.region == Region.earth;
    final hour = now.hour + now.minute / 60;
    final day = dayLight(hour);
    return Semantics(
      label: '${_form.name} em ${place.name}. São ${two(now.hour)}:${two(now.minute)}, '
          '${isSunUp(hour) ? 'com sol' : 'com lua'}${weather != null ? ', ${weather.label} em Bauru, ${weather.tempC.round()} graus' : ''}. '
          'Toque para pular.',
      child: GestureDetector(
        onTap: () {
          Sfx.tab.play();
          setState(() => _celebrate(text: false));
        },
        child: RepaintBoundary(
          child: AspectRatio(
            aspectRatio: sceneW / sceneH,
            child: CustomPaint(
              painter: _ScenePainter(
                tick: _tick,
                jump: _jump,
                sparks: _sparks,
                place: place,
                now: now,
                day: day,
                dusk: duskLight(hour),
                sunUp: isSunUp(hour),
                weather: weather,
                form: _form,
                aura: _aura,
              ),
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
    required this.sparks,
    required this.place,
    required this.now,
    required this.day,
    required this.dusk,
    required this.sunUp,
    required this.weather,
    required this.form,
    required this.aura,
  });

  final int tick, jump;
  final List<_Spark> sparks;
  final Place place;
  final DateTime now;
  final double day, dusk;
  final bool sunUp;
  final WeatherNow? weather;
  final Transformation form;
  final List<AuraParticle> aura;

  static final _labels = <String, TextPainter>{};

  bool get onEarth => place.region == Region.earth;
  double get night => 1 - day;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / sceneW, size.height / sceneH);
    canvas.clipRect(const Rect.fromLTWH(0, 0, sceneW, sceneH));
    final p = Paint();
    if (onEarth) {
      _earthSky(canvas, p);
    } else {
      _space(canvas, p);
    }
    _sunOrMoon(canvas, p, const Offset(150, 18));
    if (onEarth) _clouds(canvas, p);
    _clock(canvas);
    if (onEarth) {
      paintSkyline(canvas, place, 138, sceneW, night: night, landmarkUnit: .85);
      _rect(canvas, p, 0, 138, sceneW, 12, Color.lerp(const Color(0xFF4A4A55), const Color(0xFF26262F), night)!);
      for (var x = 4.0; x < sceneW; x += 16) {
        _rect(canvas, p, x, 143, 7, 1, Kanagawa.carpYellow.withAlpha(120));
      }
      _rain(canvas, p);
    } else {
      _body(canvas);
    }
    _hero(canvas, p);
    _plate(canvas, p);
    for (final s in sparks) {
      if (s.text != null) {
        _label(canvas, s.text!, Offset(s.x, s.y), 8, s.color.withAlpha((math.min(1.0, s.life / 20) * 255).round()));
      } else {
        _rect(canvas, p, s.x, s.y, 2, 2, s.color);
      }
    }
    // relâmpago
    if (weather?.sky == Sky.storm && tick % 160 < 3) {
      p.color = Kanagawa.fujiWhite.withAlpha(110);
      canvas.drawRect(const Rect.fromLTWH(0, 0, sceneW, sceneH), p);
    }
    canvas.restore();
  }

  void _rect(Canvas canvas, Paint p, double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w, h), p);
  }

  void _earthSky(Canvas canvas, Paint p) {
    const full = Rect.fromLTWH(0, 0, sceneW, sceneH);
    final gray = switch (weather?.sky) {
      Sky.cloudy || Sky.fog || Sky.drizzle => .45,
      Sky.rain => .6,
      Sky.storm => .75,
      _ => 0.0,
    };
    Color mix(Color dayC, Color nightC) {
      final c = Color.lerp(nightC, dayC, day)!;
      return Color.lerp(c, Color.lerp(const Color(0xFF8A8F9C), const Color(0xFF2A2A37), night)!, gray)!;
    }

    canvas.drawRect(
        full,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mix(const Color(0xFF3E7CB1), Kanagawa.sumiInk0), mix(const Color(0xFFA3D4E5), Kanagawa.waveBlue1)],
          ).createShader(full));
    if (dusk > 0) {
      canvas.drawRect(
          full,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Kanagawa.oniViolet.withAlpha(0),
                Kanagawa.sakuraPink.withAlpha((dusk * 80 * (1 - gray)).round()),
                Kanagawa.surimiOrange.withAlpha((dusk * 140 * (1 - gray)).round()),
              ],
            ).createShader(full));
    }
    if (night > .5 && gray < .5) _stars(canvas, p, 40, (night * 200).round());
  }

  void _space(Canvas canvas, Paint p) {
    _rect(canvas, p, 0, 0, sceneW, sceneH, Kanagawa.sumiInk0);
    final deep = place.region == Region.deep;
    final nebula = deep
        ? [Kanagawa.oniViolet, Kanagawa.sakuraPink, Kanagawa.crystalBlue, Kanagawa.waveRed]
        : [Kanagawa.oniViolet, Kanagawa.crystalBlue, Kanagawa.sakuraPink];
    for (var i = 0; i < (deep ? 9 : 6); i++) {
      p.color = nebula[i % nebula.length].withAlpha(deep ? 34 : 22);
      canvas.drawCircle(
          Offset(((i * 61 + place.index * 13) % 200).toDouble(), ((i * 37) % 120).toDouble()), 20.0 + (i % 3) * 10, p);
    }
    _stars(canvas, p, deep ? 110 : 80, 160 + (night * 95).round());
    if (place.kind == PlaceKind.constellation) {
      paintConstellation(canvas, place, const Rect.fromLTWH(92, 72, 102, 72), tick);
    }
  }

  void _stars(Canvas canvas, Paint p, int n, int alpha) {
    for (var i = 0; i < n; i++) {
      if (((tick >> 3) + i) % 23 == 0) continue;
      final x = ((i * 53 + 7) % 200 - tick * .015 * (i % 3 + 1)) % 200;
      final y = ((i * 29 + i * i) % 150).toDouble();
      final tw = .7 + .3 * math.sin(tick * .09 + i * 1.7);
      final c = i % 5 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
      final s = i % 9 == 0 ? 2.0 : 1.0;
      _rect(canvas, p, x.floorToDouble(), y, s, s, c.withAlpha((alpha * tw).round().clamp(0, 255)));
    }
  }

  void _sunOrMoon(Canvas canvas, Paint p, Offset c) {
    if (sunUp) {
      p.color = Kanagawa.carpYellow.withAlpha(30);
      canvas.drawCircle(c, 19, p);
      p.color = Kanagawa.carpYellow.withAlpha(55);
      canvas.drawCircle(c, 13, p);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + tick * .01;
        final r0 = 11.0 + ((tick >> 3) + i) % 2;
        for (var k = 0.0; k < (i.isEven ? 5 : 3); k++) {
          _rect(canvas, p, c.dx + math.cos(a) * (r0 + k), c.dy + math.sin(a) * (r0 + k), 1, 1, Kanagawa.surimiOrange);
        }
      }
      p.color = Kanagawa.surimiOrange;
      canvas.drawCircle(c, 9, p);
      p.color = Kanagawa.carpYellow;
      canvas.drawCircle(c, 8, p);
      _rect(canvas, p, c.dx - 5, c.dy - 5, 3, 2, const Color(0xFFFFF1C4));
    } else {
      p.color = Kanagawa.fujiWhite.withAlpha(24);
      canvas.drawCircle(c, 17, p);
      p.color = Kanagawa.fujiWhite.withAlpha(44);
      canvas.drawCircle(c, 12, p);
      final lit = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: 8.5)),
        Path()..addOval(Rect.fromCircle(center: c.translate(4.5, -2.5), radius: 7.5)),
      );
      p.color = Kanagawa.fujiWhite;
      canvas.drawPath(lit, p);
      for (final (dx, dy, w) in const [(-6.0, 0.0, 2.0), (-4.0, 4.0, 2.0), (-1.0, 6.0, 1.0)]) {
        _rect(canvas, p, c.dx + dx, c.dy + dy, w, w, Kanagawa.fujiGray.withAlpha(150));
      }
    }
  }

  void _clouds(Canvas canvas, Paint p) {
    final n = switch (weather?.sky) {
      Sky.partly => 3,
      Sky.cloudy || Sky.drizzle => 6,
      Sky.rain => 7,
      Sky.storm => 8,
      Sky.fog => 4,
      _ => weather == null ? 2 : 1,
    };
    final dark = weather?.sky == Sky.rain || weather?.sky == Sky.storm;
    final base = dark ? const Color(0xFF6E7380) : Kanagawa.fujiWhite;
    final c = Color.lerp(base, Kanagawa.sumiInk6, night * .8)!.withAlpha(dark ? 235 : 215);
    for (var i = 0; i < n; i++) {
      final w = 26.0 + (i * 17) % 22;
      final x = (i * 71 + tick * (.05 + (i % 3) * .02)) % (sceneW + 60) - 40;
      final y = 6.0 + (i * 23) % 50;
      _rect(canvas, p, x, y + 4, w, 6, c);
      _rect(canvas, p, x + 4, y, w * .45, 5, c);
      _rect(canvas, p, x + w * .45, y + 1, w * .35, 4, c);
    }
    if (weather?.sky == Sky.fog) {
      for (var i = 0; i < 3; i++) {
        _rect(canvas, p, 0, 70.0 + i * 22, sceneW, 8, Kanagawa.fujiWhite.withAlpha(60));
      }
    }
  }

  void _rain(Canvas canvas, Paint p) {
    final sky = weather?.sky;
    final n = switch (sky) {
      Sky.drizzle => 30,
      Sky.rain => 70,
      Sky.storm => 110,
      _ => 0,
    };
    for (var i = 0; i < n; i++) {
      final x = (i * 37 + tick * 1.2) % sceneW;
      final y = (i * 53 + tick * (sky == Sky.drizzle ? 3 : 6)) % sceneH;
      _rect(canvas, p, x, y, 1, sky == Sky.drizzle ? 2 : 4, Kanagawa.lightBlue.withAlpha(170));
    }
  }

  void _body(Canvas canvas) {
    switch (place.kind) {
      case PlaceKind.constellation:
        break;
      case PlaceKind.star:
        paintBody(canvas, place, const Offset(150, 118), 20, tick);
      case PlaceKind.ring:
        paintBody(canvas, place, const Offset(146, 122), 26, tick);
      default:
        paintBody(canvas, place, const Offset(130, 214), 104, tick);
    }
  }

  void _hero(Canvas canvas, Paint p) {
    const cx = 56.0;
    final jumpY = jump > 0 ? -(math.sin(jump / 26 * math.pi) * 14).roundToDouble() : 0.0;
    var o = _originOf(onEarth).translate(0, jumpY);
    if (onEarth) {
      o = o.translate(0, (tick ~/ 20) % 2 == 0 ? 0 : -1);
      p.color = const Color(0x55000000);
      canvas.drawOval(Rect.fromCenter(center: const Offset(cx, 139), width: 40 - jumpY.abs(), height: 4), p);
    } else {
      o = o.translate(0, (math.sin(tick * .04) * 4).roundToDouble());
    }
    final box = figureBox(o, _sc);
    final level = auraLevel(form, space: !onEarth);
    paintAuraBack(canvas, box, form, level, aura, tick);
    paintGrid(canvas, characterGrid(form, blink: tick % 200 < 6, tick: tick), o, _sc);
    paintAuraFront(canvas, box, form, level, tick);
  }

  void _clock(Canvas canvas) {
    final time = '${two(now.hour)}:${two(now.minute)}';
    final colon = (tick ~/ 15).isEven;
    final ink = onEarth && day > .5 ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite;
    final shadow = onEarth && day > .5 ? Kanagawa.fujiWhite.withAlpha(150) : Kanagawa.sumiInk0;
    _label(canvas, colon ? time : time.replaceFirst(':', ' '), const Offset(151, 34), 20, shadow, center: true);
    _label(canvas, colon ? time : time.replaceFirst(':', ' '), const Offset(150, 33), 20, ink, center: true);
    final date = '${dayAbbr[now.weekday - 1]} ${two(now.day)}/${two(now.month)}';
    _label(canvas, date, const Offset(150, 56), 7, ink.withAlpha(220), center: true);
    final w = weather;
    if (onEarth && w != null) {
      _label(canvas, '${w.tempC.round()}° ${w.label}', const Offset(150, 66), 6.5, ink, center: true);
      _label(canvas, 'Bauru-SP', const Offset(150, 74), 5.5, ink.withAlpha(200), center: true);
    }
  }

  void _plate(Canvas canvas, Paint p) {
    final name = place.name.toUpperCase();
    final region = regionName(place.region).toUpperCase();
    final tp = _painter(name, 6.5, Kanagawa.carpYellow);
    final w = math.max(tp.width, _painter(region, 4.5, Kanagawa.springViolet1).width) + 10;
    _rect(canvas, p, 3, 3, w + 2, 22, Kanagawa.sumiInk0);
    _rect(canvas, p, 4, 4, w, 20, Kanagawa.sumiInk4.withAlpha(235));
    _label(canvas, region, const Offset(9, 6), 4.5, Kanagawa.springViolet1);
    _label(canvas, name, const Offset(9, 13), 6.5, Kanagawa.carpYellow);
  }

  TextPainter _painter(String text, double size, Color color) {
    final key = '$text|$size|${color.toARGB32()}';
    final tp = _labels[key] ??= (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontFamily: PixelText.family, fontWeight: FontWeight.w800, fontSize: size, color: color, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout());
    if (_labels.length > 120) _labels.remove(_labels.keys.first);
    return tp;
  }

  void _label(Canvas canvas, String text, Offset at, double size, Color color, {bool center = false}) {
    final tp = _painter(text, size, color);
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}
