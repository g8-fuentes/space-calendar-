import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/transformations.dart';
import '../art/character_art.dart';
import '../art/pixel_art.dart';

/// O personagem grande, animado e com a aura da transformação, num fundo
/// escuro (pessoa ou astronauta).
class CharacterView extends StatefulWidget {
  const CharacterView({super.key, required this.form, required this.astronaut, this.locked = false});
  final Transformation form;
  final bool astronaut;

  /// Silhueta de uma transformação ainda não liberada.
  final bool locked;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> with SingleTickerProviderStateMixin {
  static const w = 120.0, h = 110.0, sc = 3.0;
  static const origin = Offset(w / 2 - 13 * sc, h - 4 - (feetRow + 1) * sc);
  late final Ticker _ticker;
  final _rand = math.Random();
  final _aura = <AuraParticle>[];
  int _tick = 0, _lastFrame = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      final frame = elapsed.inMilliseconds ~/ 33;
      if (frame == _lastFrame) return;
      final steps = _lastFrame < 0 ? 1 : (frame - _lastFrame).clamp(1, 3);
      _lastFrame = frame;
      setState(() {
        for (var i = 0; i < steps; i++) {
          _tick++;
          if (!widget.locked) stepAura(_aura, figureBox(origin, sc), widget.form, _rand);
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
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (old.form.index != widget.form.index) _aura.clear();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.locked
            ? 'Transformação ainda bloqueada'
            : '${widget.astronaut ? 'Astronauta' : 'Personagem'} na forma ${widget.form.name}',
        child: RepaintBoundary(
          child: AspectRatio(
            aspectRatio: w / h,
            child: CustomPaint(
              painter: _CharacterPainter(widget.form, widget.astronaut, widget.locked, _tick, _aura),
            ),
          ),
        ),
      );
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.form, this.astronaut, this.locked, this.tick, this.aura);
  final Transformation form;
  final bool astronaut, locked;
  final int tick;
  final List<AuraParticle> aura;

  @override
  void paint(Canvas canvas, Size size) {
    const w = _CharacterViewState.w, h = _CharacterViewState.h, sc = _CharacterViewState.sc;
    canvas.save();
    canvas.scale(size.width / w, size.height / h);
    canvas.clipRect(const Rect.fromLTWH(0, 0, w, h));
    final p = Paint()..color = Kanagawa.sumiInk0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), p);
    for (var i = 0; i < 26; i++) {
      final tw = .5 + .5 * math.sin(tick * .07 + i * 1.3);
      p.color = Kanagawa.fujiWhite.withAlpha((90 * tw).round());
      canvas.drawRect(
          Rect.fromLTWH(((i * 47 + 5) % w).floorToDouble(), ((i * 31 + i * i) % (h - 12)).floorToDouble(), 1, 1), p);
    }
    p.color = Kanagawa.sumiInk5;
    canvas.drawRect(const Rect.fromLTWH(0, h - 4, w, 4), p);
    final bob = astronaut ? (math.sin(tick * .05) * 2).roundToDouble() - 4 : ((tick ~/ 20) % 2 == 0 ? 0.0 : -1.0);
    final o = _CharacterViewState.origin.translate(0, bob);
    final box = figureBox(o, sc);
    final grid = characterGrid(form, astronaut: astronaut, blink: tick % 180 < 6, tick: tick);
    if (locked) {
      paintGrid(
          canvas,
          [
            for (final row in grid) [for (final c in row) c == null ? null : Kanagawa.sumiInk5]
          ],
          o,
          sc);
    } else {
      p.color = const Color(0x55000000);
      canvas.drawOval(Rect.fromCenter(center: const Offset(w / 2, h - 4), width: 44, height: 4), p);
      paintAuraBack(canvas, box, form, aura, tick);
      paintGrid(canvas, grid, o, sc);
      paintAuraFront(canvas, box, form, tick);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) => true;
}
