import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../app/theme/kanagawa.dart';

/// Nome da força da chama, para mostrar ao lado dela.
String flameLabel(double level) => switch (level) {
      <= 0 => 'apagada',
      < .25 => 'brasa',
      < .5 => 'acesa',
      < .8 => 'forte',
      _ => 'em labareda',
    };

/// Chama da disciplina em pixel art: cresce com as tarefas concluídas nos
/// últimos dias e vai baixando quando elas param.
class DisciplineFlame extends StatefulWidget {
  const DisciplineFlame({super.key, required this.level});

  /// 0 = apagada, 1 = labareda máxima.
  final double level;

  @override
  State<DisciplineFlame> createState() => _DisciplineFlameState();
}

class _DisciplineFlameState extends State<DisciplineFlame> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _tick = 0, _last = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final f = elapsed.inMilliseconds ~/ 66;
      if (f == _last || !mounted) return;
      _last = f;
      setState(() => _tick++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Chama da disciplina ${flameLabel(widget.level)}',
        child: CustomPaint(painter: _FlamePainter(widget.level, _tick)),
      );
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.level, this.tick);
  final double level;
  final int tick;

  static const _w = 20, _h = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final u = math.min(size.width / _w, size.height / _h);
    final ox = (size.width - _w * u) / 2, oy = size.height - _h * u;
    final p = Paint();
    void cell(num x, num y, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(ox + x * u, oy + y * u, u + .3, u + .3), p);
    }

    // lenha
    const wood = Color(0xFF7A4E2D), woodDark = Color(0xFF4A2F1B);
    for (var x = 3; x < 17; x++) {
      cell(x, _h - 2, x.isEven ? wood : woodDark);
      cell(x + (x < 10 ? 1 : -1), _h - 1, woodDark);
    }
    const base = _h - 3;
    if (level <= 0) {
      // fumaça subindo da lenha apagada
      for (var i = 0; i < 4; i++) {
        final y = base - ((tick ~/ 2 + i * 4) % 14);
        cell(9 + (i.isEven ? 0 : 1) + ((y ~/ 3) % 2), y, Kanagawa.fujiGray.withAlpha(120 - (base - y) * 7));
      }
      return;
    }
    final height = 3 + level * (_h - 7);
    final half = 2.5 + level * 6.5;
    final layers = [
      (1.0, Kanagawa.autumnRed),
      (.8, Kanagawa.surimiOrange),
      (.55, Kanagawa.carpYellow),
      if (level > .6) (.3, const Color(0xFFFFF4D6)),
    ];
    for (final (k, color) in layers) {
      final hw = half * k, hh = height * (k == 1 ? 1 : k + .1);
      for (var dx = -hw.floor(); dx <= hw.floor(); dx++) {
        final shape = 1 - math.pow(dx.abs() / (hw + .5), 1.6);
        final flicker = .8 + .2 * math.sin(tick * .55 + dx * 1.9 + k * 3);
        final colH = (hh * shape * flicker).round();
        for (var y = 0; y < colH; y++) {
          cell(10 + dx, base - y, color);
        }
      }
    }
    // faíscas
    final sparks = (level * 6).round();
    for (var i = 0; i < sparks; i++) {
      final life = (tick + i * 7) % 18;
      final x = 10 + ((i * 5) % 9) - 4 + (life ~/ 6) * (i.isEven ? 1 : -1);
      cell(x, base - height - life * .6,
          (i.isEven ? Kanagawa.carpYellow : Kanagawa.surimiOrange).withAlpha(255 - life * 12));
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) => old.tick != tick || old.level != level;
}
