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

const _floor = 132.0;

/// Canto da grade do personagem na cena (sem pulo nem balanço), em pé no
/// chão de grade.
const _origin = Offset(56 - 13 * _sc, _floor - (feetRow + 1) * _sc);

/// Cena da exploração: o dev dentro do terminal da Matrix, com a chuva de
/// código atrás, o destino da semana, a hora e o tempo de Bauru. Toque nele
/// para ele pular.
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
    stepAura(_aura, figureBox(_origin, _sc), _form, auraLevel(_form), _rand);
  }

  void _celebrate({bool text = true}) {
    _jump = 26;
    for (var i = 0; i < 18; i++) {
      _sparks.add(_Spark(58, 70, (_rand.nextDouble() - .5) * 3.4, -_rand.nextDouble() * 2.4 - 1, 40,
          i.isEven ? Px.fujiWhite : Px.carpYellow));
    }
    if (text) _sparks.add(_Spark(40, 50, 0, -.45, 55, Px.springGreen, '+1 MISSÃO'));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(burstProvider, (_, next) {
      if (next != null) _celebrate();
    });
    final stats = ref.watch(statsProvider);
    final place = widget.placeOverride ?? stats.place;
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final weather = ref.watch(weatherProvider).valueOrNull;
    _form = stats.form;
    final hour = now.hour + now.minute / 60;
    final day = dayLight(hour);
    return Semantics(
      label: '${_form.name} em ${place.name}. São ${two(now.hour)}:${two(now.minute)}, '
          '${weather != null ? ', ${weather.label} em Bauru, ${weather.tempC.round()} graus' : ''}. '
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
    required this.weather,
    required this.form,
    required this.aura,
  });

  final int tick, jump;
  final List<_Spark> sparks;
  final Place place;
  final DateTime now;
  final double day;
  final WeatherNow? weather;
  final Transformation form;
  final List<AuraParticle> aura;

  static final _labels = <String, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / sceneW, size.height / sceneH);
    const full = Rect.fromLTWH(0, 0, sceneW, sceneH);
    canvas.clipRect(full);
    final p = Paint()..color = matrixDark;
    canvas.drawRect(full, p);
    final matrix = place.kind == PlaceKind.matrix;
    // de noite a chuva de código fica mais forte
    paintRain(canvas, full, tick, density: matrix ? .95 : .45 + (1 - day) * .25, alpha: matrix ? 220 : 150);
    paintGridFloor(canvas, full, _floor, tick);
    paintPlaceObject(canvas, place, 150, _floor, .95, tick);
    _clock(canvas);
    _hero(canvas, p);
    _plate(canvas, p);
    _prompt(canvas, p);
    for (final s in sparks) {
      if (s.text != null) {
        _label(canvas, s.text!, Offset(s.x, s.y), 8, s.color.withAlpha((math.min(1.0, s.life / 20) * 255).round()));
      } else {
        _rect(canvas, p, s.x, s.y, 2, 2, s.color);
      }
    }
    // relâmpago de tempestade em Bauru vira uma falha na tela
    if (weather?.sky == Sky.storm && tick % 160 < 3) {
      p.color = matrixGreen.withAlpha(70);
      canvas.drawRect(full, p);
    }
    canvas.restore();
  }

  void _rect(Canvas canvas, Paint p, double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w, h), p);
  }

  void _hero(Canvas canvas, Paint p) {
    const cx = 56.0;
    final jumpY = jump > 0 ? -(math.sin(jump / 26 * math.pi) * 14).roundToDouble() : 0.0;
    final o = _origin.translate(0, jumpY + ((tick ~/ 20) % 2 == 0 ? 0 : -1));
    p.color = matrixGreen.withAlpha(50);
    canvas.drawOval(Rect.fromCenter(center: const Offset(cx, _floor + 1), width: 40 - jumpY.abs(), height: 4), p);
    final box = figureBox(o, _sc);
    final level = auraLevel(form);
    paintAuraBack(canvas, box, form, level, aura, tick);
    paintGrid(canvas, characterGrid(form, blink: tick % 200 < 6, tick: tick), o, _sc);
    paintAuraFront(canvas, box, form, level, tick);
  }

  /// Prompt piscando no pé da cena.
  void _prompt(Canvas canvas, Paint p) {
    final text = 'dev@matrix:${place.path}\$';
    final tp = _painter(text, 5, matrixGreen);
    _rect(canvas, p, 0, sceneH - 10, sceneW, 10, matrixDark.withAlpha(220));
    tp.paint(canvas, const Offset(4, sceneH - 8.5));
    if ((tick ~/ 15).isEven) _rect(canvas, p, 6 + tp.width, sceneH - 8.5, 3, 6, matrixGreen);
  }

  void _clock(Canvas canvas) {
    final time = '${two(now.hour)}:${two(now.minute)}';
    final colon = (tick ~/ 15).isEven;
    const ink = Color(0xFFD8FFE0);
    const shadow = Color(0xFF0E5A22);
    _label(canvas, colon ? time : time.replaceFirst(':', ' '), const Offset(151, 34), 20, shadow, center: true);
    _label(canvas, colon ? time : time.replaceFirst(':', ' '), const Offset(150, 33), 20, ink, center: true);
    final date = '${dayAbbr[now.weekday - 1]} ${two(now.day)}/${two(now.month)}';
    _label(canvas, date, const Offset(150, 56), 7, ink.withAlpha(220), center: true);
    final w = weather;
    if (w != null) {
      _label(canvas, '${w.tempC.round()}° ${w.label}', const Offset(150, 66), 6.5, ink, center: true);
      _label(canvas, 'Bauru-SP', const Offset(150, 74), 5.5, ink.withAlpha(200), center: true);
    }
  }

  void _plate(Canvas canvas, Paint p) {
    final name = place.name.toUpperCase();
    final region = place.region.toUpperCase();
    final tp = _painter(name, 6.5, matrixGreen);
    final w = math.max(tp.width, _painter(region, 4.5, const Color(0xFF9FD8A6)).width) + 10;
    _rect(canvas, p, 3, 3, w + 2, 22, matrixGreen.withAlpha(170));
    _rect(canvas, p, 4, 4, w, 20, matrixDark.withAlpha(235));
    _label(canvas, region, const Offset(9, 6), 4.5, const Color(0xFF9FD8A6));
    _label(canvas, name, const Offset(9, 13), 6.5, matrixGreen);
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
