import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'sfx.dart';

/// Música de fundo em estilo 8/16 bits, composta e sintetizada no próprio
/// app: pulso para a melodia, triângulo no baixo, arpejo e bateria de ruído.
class Song {
  const Song(this.title, this.root, this.bpm, this.scale, this.chords, this.seed, {this.echo = false, this.duty = .25});
  final String title;

  /// Nota MIDI da tônica.
  final int root;
  final int bpm;
  final List<int> scale;

  /// Um acorde por compasso, em semitons a partir da tônica.
  final List<List<int>> chords;
  final int seed;

  /// Eco na melodia (som mais "16 bits").
  final bool echo;
  final double duty;
}

const _major = [0, 2, 4, 5, 7, 9, 11];
const _minor = [0, 2, 3, 5, 7, 8, 10];

const songs = [
  Song(
      'Órbita',
      60,
      128,
      _major,
      [
        [0, 4, 7],
        [7, 11, 14],
        [9, 12, 16],
        [5, 9, 12]
      ],
      11),
  Song(
      'Nebulosa',
      57,
      96,
      _minor,
      [
        [0, 3, 7],
        [8, 12, 15],
        [3, 7, 10],
        [10, 14, 17]
      ],
      23,
      echo: true,
      duty: .5),
  Song(
      'Glória',
      62,
      150,
      _minor,
      [
        [0, 3, 7],
        [5, 9, 12],
        [0, 3, 7],
        [10, 14, 17]
      ],
      37,
      duty: .125),
  Song(
      'Base lunar',
      65,
      112,
      _major,
      [
        [0, 4, 7],
        [9, 12, 16],
        [2, 5, 9],
        [7, 11, 14]
      ],
      41,
      echo: true),
];

const _rate = 22050;

double _freq(num midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// Ritmos de um compasso: (início, duração) em semicolcheias.
const _rhythms = [
  [(0, 2), (2, 2), (4, 4), (8, 2), (10, 2), (12, 4)],
  [(0, 3), (3, 1), (4, 2), (6, 2), (8, 6), (14, 2)],
  [(0, 2), (4, 2), (6, 2), (8, 4), (12, 2), (14, 2)],
  [(0, 6), (6, 2), (8, 2), (10, 2), (12, 4)],
  [(0, 2), (2, 1), (3, 1), (4, 4), (8, 4), (12, 2), (14, 2)],
];

typedef _Note = (int step, int len, int midi);

/// Gera a melodia de 4 compassos: tempos fortes em notas do acorde,
/// o resto anda pela escala.
List<_Note> _phrase(Song s, int seed, int octave, {int? endOn}) {
  final r = math.Random(seed);
  final pool = <int>[
    for (var o = -1; o <= 2; o++)
      for (final d in s.scale) s.root + octave + o * 12 + d,
  ]..sort();
  var cur = pool.indexWhere((m) => m >= s.root + octave);
  final out = <_Note>[];
  for (var bar = 0; bar < 4; bar++) {
    final chord = s.chords[bar % s.chords.length].map((c) => (s.root + c) % 12).toSet();
    final rhythm = _rhythms[r.nextInt(_rhythms.length)];
    for (final (st, len) in rhythm) {
      if (st == 0 || st == 8 || len >= 4) {
        // nota do acorde mais próxima
        var best = cur, bestD = 99;
        for (var i = 0; i < pool.length; i++) {
          if (!chord.contains(pool[i] % 12)) continue;
          final d = (i - cur).abs() + (r.nextInt(3) == 0 ? 1 : 0);
          if (d < bestD) {
            bestD = d;
            best = i;
          }
        }
        cur = best;
      } else {
        cur += const [-2, -1, -1, 1, 1, 2][r.nextInt(6)];
      }
      final lo = pool.indexWhere((m) => m >= s.root + octave - 3);
      final hi = pool.lastIndexWhere((m) => m <= s.root + octave + 16);
      cur = cur.clamp(lo, hi);
      out.add((bar * 16 + st, len, pool[cur]));
    }
  }
  if (endOn != null && out.isNotEmpty) {
    final last = out.removeLast();
    out.add((last.$1, 16 - last.$1 % 16 + 0, s.root + octave + endOn));
  }
  return out;
}

Float64List renderSong(Song s) {
  final stepSec = 60 / s.bpm / 4;
  const bars = 16;
  final n = (bars * 16 * stepSec * _rate).round();
  final out = Float64List(n);
  final noise = math.Random(s.seed);

  void tone(double startSec, double dur, double freq, double vol, double duty,
      {bool tri = false, bool vibrato = false}) {
    final a = (startSec * _rate).round(), len = (dur * _rate).round();
    var phase = 0.0;
    for (var i = 0; i < len && a + i < n; i++) {
      final t = i / _rate;
      final f = vibrato && t > .15 ? freq * (1 + .006 * math.sin(t * 2 * math.pi * 5.5)) : freq;
      phase += f / _rate;
      final p = phase - phase.floorToDouble();
      final v = tri ? 4 * (p - .5).abs() - 1 : (p < duty ? 1.0 : -1.0);
      final x = i / len;
      final env = math.min(1.0, i / (_rate * .004)) * (x > .85 ? (1 - x) / .15 : 1) * (1 - .35 * x);
      out[a + i] += v * vol * env;
    }
  }

  void drum(double startSec, String kind) {
    final a = (startSec * _rate).round();
    final len = ((kind == 'kick'
                ? .14
                : kind == 'snare'
                    ? .12
                    : .035) *
            _rate)
        .round();
    var phase = 0.0, last = 0.0;
    for (var i = 0; i < len && a + i < n; i++) {
      final x = i / len;
      double v;
      if (kind == 'kick') {
        phase += (110 * math.pow(.3, x)) / _rate;
        v = math.sin(phase * 2 * math.pi) * .5;
      } else {
        final w = noise.nextDouble() * 2 - 1;
        v = kind == 'hat' ? (w - last) * .5 : w * .22 + math.sin(i / _rate * 2 * math.pi * 190) * .12;
        last = w;
      }
      out[a + i] += v * math.pow(1 - x, 2) * (kind == 'hat' ? .25 : 1);
    }
  }

  final a1 = _phrase(s, s.seed, 12);
  final a2 = [...a1.where((x) => x.$1 < 48), ..._phrase(s, s.seed + 5, 12, endOn: 0).where((x) => x.$1 >= 48)];
  final b = _phrase(s, s.seed + 9, 19);
  final sections = [a1, a2, b, a2];

  for (var bar = 0; bar < bars; bar++) {
    final chord = s.chords[bar % s.chords.length];
    final t0 = bar * 16 * stepSec;
    final section = bar ~/ 4;
    // baixo: tônica e oitava em colcheias
    for (var k = 0; k < 8; k++) {
      final midi = s.root - 24 + chord[0] + (k.isOdd ? 12 : 0);
      tone(t0 + k * 2 * stepSec, stepSec * 1.8, _freq(midi), .2, .5, tri: true);
    }
    // arpejo baixinho em semicolcheias
    for (var k = 0; k < 16; k++) {
      final c = chord[const [0, 1, 2, 1][k % 4]];
      tone(t0 + k * stepSec, stepSec * .9, _freq(s.root + c), .045, .125);
    }
    // bateria a partir da segunda parte
    if (section > 0) {
      for (var k = 0; k < 16; k++) {
        final at = t0 + k * stepSec;
        if (k == 0 || k == 8 || (s.bpm > 120 && k == 10)) drum(at, 'kick');
        if (k == 4 || k == 12) drum(at, 'snare');
        if (k.isEven) drum(at, 'hat');
      }
    }
  }
  for (var sec = 0; sec < 4; sec++) {
    for (final (st, len, midi) in sections[sec]) {
      final at = (sec * 64 + st) * stepSec, dur = len * stepSec * .92;
      tone(at, dur, _freq(midi), .16, s.duty, vibrato: len >= 4);
      if (s.echo) tone(at + 3 * stepSec, dur, _freq(midi), .06, s.duty);
    }
  }
  var peak = 0.0;
  for (final v in out) {
    peak = math.max(peak, v.abs());
  }
  if (peak > 0) {
    final k = .9 / peak;
    for (var i = 0; i < n; i++) {
      out[i] *= k;
    }
  }
  return out;
}

/// Roda num isolate: compõe a música [args.$1] e grava em [args.$2].
Future<String> renderSongToFile((int, String) args) async {
  final f = File(args.$2);
  await f.writeAsBytes(wavFromSamples(renderSong(songs[args.$1]), _rate), flush: true);
  return f.path;
}

/// Toca as músicas em sequência, só com o app aberto e a música ligada.
class MusicBox {
  MusicBox._();
  static final instance = MusicBox._();

  final _paths = <String>[];
  AudioPlayer? _player;
  int _track = 0;
  bool _enabled = true, _foreground = true, _playing = false, _started = false;

  bool get enabled => _enabled;
  set enabled(bool v) {
    if (v == _enabled) return;
    _enabled = v;
    unawaited(_apply());
  }

  /// Chamado pelo ciclo de vida do app: pausa ao ir para segundo plano.
  void setForeground(bool v) {
    if (v == _foreground) return;
    _foreground = v;
    unawaited(_apply());
  }

  Future<void> init() async {
    try {
      final dir = await getTemporaryDirectory();
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.release);
      await p.setVolume(.4);
      p.onPlayerComplete.listen((_) {
        _started = false;
        _playing = false;
        _track = (_track + 1) % _paths.length;
        unawaited(_apply());
      });
      _player = p;
      _track = math.Random().nextInt(songs.length);
      final order = [for (var i = 0; i < songs.length; i++) (_track + i) % songs.length];
      final ready = <int, String>{};
      for (final i in order) {
        ready[i] = await compute(renderSongToFile, (i, '${dir.path}/rq_music_$i.wav'));
        if (i == _track) {
          _paths
            ..clear()
            ..addAll(List.filled(songs.length, ready[i]!));
          unawaited(_apply());
        }
      }
      for (var i = 0; i < songs.length; i++) {
        _paths[i] = ready[i]!;
      }
    } catch (e) {
      debugPrint('Música desligada: $e');
    }
  }

  Future<void> _apply() async {
    final p = _player;
    if (p == null || _paths.isEmpty) return;
    try {
      if (_enabled && _foreground) {
        if (_playing) return;
        _playing = true;
        if (_started) {
          await p.resume();
        } else {
          _started = true;
          await p.play(DeviceFileSource(_paths[_track]));
        }
      } else if (_playing) {
        _playing = false;
        await p.pause();
      }
    } catch (e) {
      debugPrint('Música: $e');
    }
  }
}
