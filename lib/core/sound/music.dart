import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'sfx.dart';

/// Música de fundo eletrônica e instrumental, composta e sintetizada no
/// próprio app: bumbo quatro por quatro, chimbal, palmas, baixo de serra
/// filtrado, pad e arpejo. Sem voz e sem melodia cantada: só ritmo.
class Song {
  const Song(this.title, this.root, this.bpm, this.chords, this.seed,
      {this.style = Groove.house, this.arp = true, this.pad = true});
  final String title;

  /// Nota MIDI da tônica.
  final int root;
  final int bpm;

  /// Um acorde por compasso, em semitons a partir da tônica.
  final List<List<int>> chords;
  final int seed;
  final Groove style;
  final bool arp, pad;
}

/// Jeito da batida.
enum Groove {
  /// Bumbo em todo tempo e chimbal aberto no contratempo.
  house,

  /// Bumbo seco, baixo rolando em semicolcheias.
  techno,

  /// Mais lento, caixa no 2 e no 4, baixo longo.
  synthwave,

  /// Quebrado: bumbo e caixa fora do lugar, chimbal rápido.
  breaks,
}

const songs = [
  Song(
      'Compilando',
      45,
      124,
      [
        [0, 3, 7, 10],
        [0, 3, 7, 10],
        [8, 12, 15, 19],
        [5, 8, 12, 15]
      ],
      11),
  Song(
      'Chuva de código',
      43,
      132,
      [
        [0, 3, 7],
        [0, 3, 7],
        [10, 14, 17],
        [8, 12, 15]
      ],
      23,
      style: Groove.techno,
      pad: false),
  Song(
      'Neon',
      48,
      100,
      [
        [0, 3, 7, 10],
        [8, 12, 15, 19],
        [3, 7, 10, 14],
        [10, 14, 17, 21]
      ],
      37,
      style: Groove.synthwave),
  Song(
      'Root',
      41,
      140,
      [
        [0, 3, 7],
        [5, 8, 12],
        [0, 3, 7],
        [3, 7, 10]
      ],
      41,
      style: Groove.breaks,
      arp: false),
];

const _rate = 22050;

double _freq(num midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

Float64List renderSong(Song s) {
  final stepSec = 60 / s.bpm / 4;
  const bars = 16;
  final n = (bars * 16 * stepSec * _rate).round();
  final out = Float64List(n);
  final duck = Float64List(n)..fillRange(0, n, 1);
  final noise = math.Random(s.seed);

  /// Serra (ou quadrada) passando por um filtro passa-baixa simples.
  void synth(double startSec, double dur, double freq, double vol,
      {double cutoff = 1200, double attack = .005, bool square = false, double detune = 0, bool ducked = true}) {
    final a = (startSec * _rate).round(), len = (dur * _rate).round();
    final k = 1 - math.exp(-2 * math.pi * cutoff / _rate);
    var ph1 = 0.0, ph2 = .3, lp = 0.0;
    for (var i = 0; i < len && a + i < n; i++) {
      ph1 += freq / _rate;
      ph2 += freq * (1 + detune) / _rate;
      final p1 = ph1 - ph1.floorToDouble(), p2 = ph2 - ph2.floorToDouble();
      final raw = square
          ? (p1 < .5 ? 1.0 : -1.0)
          : detune == 0
              ? 2 * p1 - 1
              : (2 * p1 - 1 + 2 * p2 - 1) * .5;
      lp += k * (raw - lp);
      final x = i / len;
      final env = math.min(1.0, i / (_rate * attack)) * (x > .8 ? (1 - x) / .2 : 1);
      out[a + i] += lp * vol * env * (ducked ? duck[a + i] : 1);
    }
  }

  void drum(double startSec, String kind, {double vol = 1}) {
    final a = (startSec * _rate).round();
    final dur = switch (kind) { 'kick' => .22, 'clap' => .16, 'open' => .12, _ => .03 };
    final len = (dur * _rate).round();
    var phase = 0.0, last = 0.0;
    for (var i = 0; i < len && a + i < n; i++) {
      final x = i / len;
      double v;
      switch (kind) {
        case 'kick':
          phase += (45 + 120 * math.pow(.02, x)) / _rate;
          v = math.sin(phase * 2 * math.pi) * .9 * math.pow(1 - x, 1.5);
          // o bumbo abaixa o resto por um instante (efeito "sidechain")
          duck[a + i] = math.min(duck[a + i], .35 + .65 * x);
        case 'clap':
          final w = noise.nextDouble() * 2 - 1;
          final burst = x < .12 ? (((x * 40).floor()).isEven ? 1.0 : .3) : 1.0;
          v = (w - last * .6) * .35 * burst * math.pow(1 - x, 2.5);
          last = w;
        default:
          final w = noise.nextDouble() * 2 - 1;
          v = (w - last) * .3 * math.pow(1 - x, kind == 'open' ? 1.2 : 3);
          last = w;
      }
      out[a + i] += v * vol;
    }
  }

  final r = math.Random(s.seed);
  // padrão de arpejo fixo para a música inteira, como um loop
  final arpSteps = [for (var k = 0; k < 16; k++) r.nextInt(5) == 0 ? -1 : r.nextInt(4)];
  final arpOct = [for (var k = 0; k < 16; k++) r.nextInt(3) == 0 ? 12 : 0];

  for (var bar = 0; bar < bars; bar++) {
    final chord = s.chords[bar % s.chords.length];
    final t0 = bar * 16 * stepSec;
    final section = bar ~/ 4; // 0 = entrada, 1 e 2 = cheio, 3 = sem bumbo no fim
    final full = section == 1 || section == 2;
    final kickOn = section < 3 || bar % 4 < 2;
    // bateria
    for (var k = 0; k < 16; k++) {
      final at = t0 + k * stepSec;
      switch (s.style) {
        case Groove.house || Groove.techno:
          if (k % 4 == 0 && kickOn) drum(at, 'kick');
          if (section > 0 && (k == 4 || k == 12)) drum(at, 'clap', vol: s.style == Groove.techno ? .6 : 1);
          if (k % 4 == 2) drum(at, 'open', vol: .7);
          if (full && s.style == Groove.techno) drum(at, 'hat', vol: .6);
        case Groove.synthwave:
          if ((k == 0 || k == 8 || k == 10) && kickOn) drum(at, 'kick');
          if (k == 4 || k == 12) drum(at, 'clap');
          if (k.isEven) drum(at, 'hat', vol: .7);
        case Groove.breaks:
          if ((k == 0 || k == 6 || k == 10) && kickOn) drum(at, 'kick');
          if (k == 4 || k == 12 || (full && k == 15)) drum(at, 'clap');
          drum(at, 'hat', vol: k.isEven ? .8 : .45);
      }
    }
    // baixo
    final bassMidi = s.root - 12 + chord[0];
    switch (s.style) {
      case Groove.house:
        for (var k = 2; k < 16; k += 4) {
          synth(t0 + k * stepSec, stepSec * 1.6, _freq(bassMidi), .32, cutoff: 500);
        }
      case Groove.techno:
        for (var k = 0; k < 16; k++) {
          if (k % 4 == 0) continue;
          synth(t0 + k * stepSec, stepSec * .8, _freq(bassMidi + (k % 8 == 7 ? 12 : 0)), .26,
              cutoff: 300 + 500 * (bar % 4) / 3);
        }
      case Groove.synthwave:
        for (var k = 0; k < 16; k += 2) {
          synth(t0 + k * stepSec, stepSec * 1.7, _freq(bassMidi + (k % 4 == 2 ? 12 : 0)), .26, cutoff: 700);
        }
      case Groove.breaks:
        for (final k in const [0, 3, 6, 10, 11]) {
          synth(t0 + k * stepSec, stepSec * 1.4, _freq(bassMidi), .3, cutoff: 600, square: true);
        }
    }
    // pad: acorde longo e suave, abrindo o filtro na parte cheia
    if (s.pad && section > 0) {
      for (final c in chord) {
        synth(t0, 16 * stepSec, _freq(s.root + 12 + c), .045, cutoff: full ? 1600 : 800, attack: .25, detune: .006);
      }
    }
    // arpejo
    if (s.arp && section > 0) {
      for (var k = 0; k < 16; k++) {
        final step = arpSteps[k];
        if (step < 0) continue;
        final c = chord[step % chord.length];
        synth(t0 + k * stepSec, stepSec * .7, _freq(s.root + 24 + c + arpOct[k]), .06,
            cutoff: full ? 2600 : 1400, square: true);
      }
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
