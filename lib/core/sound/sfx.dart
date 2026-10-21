import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum Wave { square, triangle, sawtooth }

/// Uma nota: frequência inicial, duração e frequência final (glissando).
typedef Note = (double freq, double seconds, double? to);

/// Efeitos sonoros 8-bit gerados no próprio app (sem arquivos de áudio).
enum Sfx {
  click([(1200, .03, null)]),
  tab([(520, .04, null), (780, .05, null)]),
  done([(660, .07, null), (990, .11, null)]),
  undo([(440, .08, null), (300, .12, null)]),
  level([(523, .1, null), (659, .1, null), (784, .1, null), (1047, .28, null)]),
  chest([(392, .08, null), (523, .08, null), (659, .08, null), (784, .08, null), (1047, .3, null)]),
  buy([(880, .06, null), (1175, .13, null)]),
  equip([(300, .05, null), (600, .07, null)], Wave.triangle),
  power([(200, .25, 900)], Wave.sawtooth),
  delete([(300, .08, null), (180, .16, null)], Wave.triangle),
  save([(700, .05, null), (900, .05, null), (1100, .08, null)]),
  error([(160, .18, null)], Wave.sawtooth),
  foe([(110, .2, 70), (90, .3, 60)], Wave.sawtooth),
  launch([(80, .6, 600)], Wave.sawtooth),
  lesson([(784, .05, null), (988, .05, null), (1319, .1, null)]);

  const Sfx(this.notes, [this.wave = Wave.square]);
  final List<Note> notes;
  final Wave wave;

  void play() => SoundBoard.instance.play(this);
}

class SoundBoard {
  SoundBoard._();
  static final instance = SoundBoard._();

  bool enabled = true;
  final _paths = <Sfx, String>{};
  final _players = <AudioPlayer>[];
  var _next = 0;
  bool _ready = false;

  /// Gera os arquivos .wav na pasta temporária. Falhas deixam o jogo mudo,
  /// nunca travado.
  Future<void> init() async {
    try {
      final dir = await getTemporaryDirectory();
      for (final s in Sfx.values) {
        final f = File('${dir.path}/rq_${s.name}.wav');
        await f.writeAsBytes(synthesize(s.notes, s.wave), flush: true);
        _paths[s] = f.path;
      }
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        // Sem pedir foco de áudio: senão cada efeito pausaria a música.
        await p.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
          ),
        ));
        _players.add(p);
      }
      _ready = true;
    } catch (e) {
      debugPrint('Sons desligados: $e');
    }
  }

  void play(Sfx s) {
    if (!enabled || !_ready) return;
    final path = _paths[s];
    if (path == null) return;
    final p = _players[_next++ % _players.length];
    p.play(DeviceFileSource(path)).catchError((Object _) {});
  }
}

/// WAV mono 16 bits, com cada nota decaindo como no jogo em HTML.
Uint8List synthesize(List<Note> notes, Wave wave, {int rate = 22050}) {
  var total = 0.0, t = 0.0;
  for (final (_, d, _) in notes) {
    total = math.max(total, t + d);
    t += d * .9;
  }
  final n = (total * rate).ceil() + 1;
  final samples = Float64List(n);
  t = 0;
  for (final (f0, d, f1) in notes) {
    final start = (t * rate).round(), len = (d * rate).round();
    var phase = 0.0;
    for (var i = 0; i < len && start + i < n; i++) {
      final x = i / len;
      final f = f1 == null ? f0 : f0 * math.pow(f1 / f0, x);
      phase += f / rate;
      final p = phase - phase.floorToDouble();
      final v = switch (wave) {
        Wave.square => p < .5 ? 1.0 : -1.0,
        Wave.triangle => 4 * (p - .5).abs() - 1,
        Wave.sawtooth => 2 * p - 1,
      };
      final gain = .25 * math.pow(.02, x);
      samples[start + i] += v * gain;
    }
    t += d * .9;
  }
  return wavFromSamples(samples, rate);
}

/// Empacota amostras (-1 a 1) num WAV mono de 16 bits.
Uint8List wavFromSamples(Float64List samples, int rate) {
  final n = samples.length;
  final bytes = ByteData(44 + n * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bytes.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bytes.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    bytes.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}
