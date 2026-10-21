import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';

/// Grade de pixels: null = transparente.
typedef PixelGrid = List<List<Color?>>;

const _skin = Color(0xFFE8B48A);
const _skinDark = Color(0xFFC98E66);
const _hair = Color(0xFF2E1D14);
const _ink = Kanagawa.sumiInk0;

/// Astronauta: capacete grande, rosto no visor, traje com painel de
/// luzes e tanques nas costas. [equipped] liga slot -> item da loja.
PixelGrid astronautGrid({
  required int rank,
  required int mk,
  required Map<String, String> equipped,
  bool blink = false,
  int tick = 0,
}) {
  const w = 26, h = 32, ox = 5, oy = 3;
  final g = List.generate(h, (_) => List<Color?>.filled(w, null));
  void r(int x, int y, int rw, int rh, Color c) {
    for (var j = y + oy; j < y + oy + rh; j++) {
      for (var i = x + ox; i < x + ox + rw; i++) {
        if (j >= 0 && j < h && i >= 0 && i < w) g[j][i] = c;
      }
    }
  }

  var suit = Color(suitColor(mk));
  var accent = Color(suitAccent(mk));
  final skin = equipped['skin'] == null ? null : shopItem(equipped['skin']!);
  if (skin != null) {
    suit = skin.isAurora ? Color(hslToArgb(((tick * 2) % 360).toDouble(), .55, .66)) : Color(skin.suit!);
    accent = Color(skin.accent!);
  }
  final head = equipped['head'], face = equipped['face'], body = equipped['body'];

  if (equipped['back'] == 'cape') {
    r(2, 10, 12, 12, Kanagawa.autumnRed);
    r(2, 21, 12, 1, const Color(0xFF8A2C2E));
  }
  // tanques
  r(1, 11, 2, 6, Kanagawa.fujiGray);
  r(13, 11, 2, 6, Kanagawa.fujiGray);
  r(1, 16, 2, 1, Kanagawa.sumiInk6);
  r(13, 16, 2, 1, Kanagawa.sumiInk6);
  // capacete
  r(5, 0, 6, 1, Kanagawa.fujiWhite);
  r(4, 1, 8, 1, Kanagawa.fujiWhite);
  r(3, 2, 10, 7, Kanagawa.fujiWhite);
  r(4, 9, 8, 1, Kanagawa.oldWhite);
  r(3, 8, 10, 1, Kanagawa.oldWhite);
  if (head == 'catears') {
    r(3, 0, 2, 2, Kanagawa.fujiWhite);
    r(3, -1, 1, 1, Kanagawa.fujiWhite);
    r(11, 0, 2, 2, Kanagawa.fujiWhite);
    r(12, -1, 1, 1, Kanagawa.fujiWhite);
    r(4, 0, 1, 1, Kanagawa.sakuraPink);
    r(11, 0, 1, 1, Kanagawa.sakuraPink);
  }
  // visor e rosto
  r(4, 3, 8, 5, face == 'visor' ? Kanagawa.carpYellow : face == 'neon' ? Kanagawa.waveBlue2 : Kanagawa.waveBlue1);
  if (face != 'visor') {
    r(5, 4, 6, 3, _skin);
    r(5, 4, 6, 1, _hair);
    r(5, 5, 1, 1, _hair);
    r(6, 5, 1, 1, blink ? _skinDark : _ink);
    r(9, 5, 1, 1, blink ? _skinDark : _ink);
    r(7, 6, 2, 1, _skinDark);
  }
  if (face == 'neon') {
    r(4, 3, 8, 1, Kanagawa.springBlue);
    r(4, 7, 8, 1, Kanagawa.springBlue);
  }
  r(10, 3, 1, 1, Kanagawa.lightBlue);
  r(11, 4, 1, 1, Kanagawa.lightBlue);
  if (head == 'antenna') {
    r(11, -2, 1, 2, Kanagawa.fujiGray);
    r(11, -3, 1, 1, Kanagawa.autumnRed);
  }
  if (head == 'crown') {
    r(5, -2, 6, 2, Kanagawa.carpYellow);
    r(5, -3, 1, 1, Kanagawa.carpYellow);
    r(7, -3, 2, 1, Kanagawa.carpYellow);
    r(10, -3, 1, 1, Kanagawa.carpYellow);
    r(7, -2, 2, 1, Kanagawa.autumnRed);
  }
  // corpo
  r(4, 10, 8, 6, suit);
  r(4, 15, 8, 1, accent);
  r(6, 11, 4, 2, _ink);
  r(6, 11, 1, 1, Kanagawa.autumnRed);
  r(7, 11, 1, 1, Kanagawa.springGreen);
  r(8, 11, 1, 1, Kanagawa.springBlue);
  r(9, 12, 1, 1, Kanagawa.carpYellow);
  for (var i = 0; i < math.min(5, rank); i++) {
    r(5 + i, 14, 1, 1, Kanagawa.carpYellow);
  }
  if (body == 'stickers') {
    r(10, 11, 1, 2, Kanagawa.surimiOrange);
    r(5, 12, 1, 1, Kanagawa.springBlue);
  }
  if (body == 'scarf') {
    r(4, 10, 8, 1, Kanagawa.oniViolet);
    r(10, 10, 2, 3, Kanagawa.oniViolet);
    r(11, 13, 1, 1, Kanagawa.sakuraPink);
  }
  // braços
  r(2, 10, 2, 5, suit);
  r(12, 10, 2, 5, suit);
  r(2, 15, 2, 1, accent);
  r(12, 15, 2, 1, accent);
  if (rank >= 2) r(2, 11, 2, 1, accent);
  if (rank >= 3) r(12, 11, 2, 1, Kanagawa.carpYellow);
  // pernas
  r(4, 16, 3, 5, suit);
  r(9, 16, 3, 5, suit);
  r(4, 21, 3, 1, accent);
  r(9, 21, 3, 1, accent);
  r(4, 20, 3, 1, _ink);
  r(9, 20, 3, 1, _ink);
  if (rank >= 4) {
    r(4, 18, 3, 1, accent);
    r(9, 18, 3, 1, accent);
  }
  final hand = equipped['hand'];
  if (hand == 'flag') {
    r(14, 6, 1, 10, Kanagawa.fujiGray);
    r(15, 6, 4, 3, Kanagawa.autumnRed);
    r(15, 7, 2, 1, Kanagawa.fujiWhite);
  }
  if (hand == 'saber') {
    r(14, 13, 1, 3, Kanagawa.fujiGray);
    r(14, 4, 1, 9, (tick >> 3).isOdd ? Kanagawa.lightBlue : Kanagawa.springBlue);
    r(14, 3, 1, 1, Kanagawa.fujiWhite);
  }
  return outlined(g);
}

PixelGrid outlined(PixelGrid g) {
  final h = g.length, w = g.first.length;
  final out = [for (final row in g) List<Color?>.of(row)];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (g[y][x] != null) continue;
      final near = (y > 0 && g[y - 1][x] != null) ||
          (y < h - 1 && g[y + 1][x] != null) ||
          (x > 0 && g[y][x - 1] != null) ||
          (x < w - 1 && g[y][x + 1] != null);
      if (near) out[y][x] = _ink;
    }
  }
  return out;
}

void paintGrid(Canvas canvas, PixelGrid g, Offset origin, double scale) {
  final paint = Paint();
  for (var j = 0; j < g.length; j++) {
    for (var i = 0; i < g[j].length; i++) {
      final c = g[j][i];
      if (c == null) continue;
      paint.color = c;
      canvas.drawRect(Rect.fromLTWH(origin.dx + i * scale, origin.dy + j * scale, scale + 0.3, scale + 0.3), paint);
    }
  }
}

final _enemyGrids = <int, PixelGrid>{};

PixelGrid enemyGrid(Enemy e) => _enemyGrids.putIfAbsent(
    e.level, () => [for (final row in e.grid) [for (final c in row) c == 0 ? null : Color(c)]]);

/// Inimigo centralizado num quadrado de lado [box].
void paintEnemyFitted(Canvas canvas, Enemy e, Offset topLeft, double box) {
  final s = (box / e.size).floorToDouble();
  final pad = (box - e.size * s) / 2;
  paintGrid(canvas, enemyGrid(e), topLeft + Offset(pad, pad), s);
}

/// Companheiros da loja.
void paintPet(Canvas canvas, String id, Offset o, int tick) {
  final p = Paint();
  void r(double x, double y, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(o.dx + x, o.dy + y, w, h), p);
  }

  switch (id) {
    case 'robot':
      r(0, 0, 10, 8, _ink);
      r(1, 1, 8, 6, Kanagawa.springViolet1);
      r(2, 2, 6, 3, Kanagawa.waveBlue1);
      r(3, 3, 1, 1, Kanagawa.springBlue);
      r(6, 3, 1, 1, Kanagawa.springBlue);
      r(4, -2, 1, 2, _ink);
      r(4, -3, 1, 1, Kanagawa.autumnRed);
      r(2, 8, 6, 2, _ink);
      r(3, 8, 4, 1, Kanagawa.surimiOrange);
    case 'sat':
      r(0, 2, 4, 3, Kanagawa.springBlue);
      r(4, 1, 4, 5, _ink);
      r(5, 2, 2, 3, Kanagawa.carpYellow);
      r(8, 2, 4, 3, Kanagawa.springBlue);
      r(5, 0, 2, 1, Kanagawa.fujiWhite);
    case 'cat':
      r(-1, -2, 12, 12, const Color(0x40A3D4D5));
      r(1, 2, 8, 6, _ink);
      r(2, 3, 6, 5, Kanagawa.surimiOrange);
      r(2, 1, 2, 2, Kanagawa.surimiOrange);
      r(6, 1, 2, 2, Kanagawa.surimiOrange);
      r(3, 4, 1, 1, _ink);
      r(6, 4, 1, 1, _ink);
      r(4, 6, 2, 1, Kanagawa.sakuraPink);
      r(8, 7, 3, 1, Kanagawa.surimiOrange);
    case 'octo':
      r(1, 0, 8, 6, _ink);
      r(2, 1, 6, 5, Kanagawa.oniViolet);
      r(3, 2, 1, 2, Kanagawa.fujiWhite);
      r(6, 2, 1, 2, Kanagawa.fujiWhite);
      r(3, 3, 1, 1, _ink);
      r(6, 3, 1, 1, _ink);
      final wv = (tick >> 3) % 2;
      for (var i = 0; i < 4; i++) {
        r(2 + i * 2.0, 6, 1, 2 + ((i + wv) % 2).toDouble(), Kanagawa.oniViolet);
      }
    case 'dragon':
      r(0, 3, 10, 5, _ink);
      r(1, 4, 8, 3, Kanagawa.springGreen);
      r(7, 1, 4, 4, _ink);
      r(8, 2, 2, 2, Kanagawa.springGreen);
      r(9, 2, 1, 1, Kanagawa.carpYellow);
      r(2, (tick >> 3).isOdd ? 1 : 2, 4, 2, Kanagawa.autumnGreen);
      r(-2, 6, 3, 1, Kanagawa.springGreen);
      if ((tick >> 2) % 4 == 0) r(12, 3, 1, 1, Kanagawa.carpYellow);
  }
}

/// Planeta, lua, cinturão ou estrela desenhado em linhas de pixel.
void paintBody(Canvas canvas, Destination d, Offset center, double radius, int tick) {
  final paint = Paint();
  final colors = d.colors.map(Color.new).toList();
  final seed = seedHash(d.index + 7);
  final cx = center.dx, cy = center.dy;
  final r = radius.roundToDouble();

  void rect(double x, double y, double w, double h, Color c) {
    paint.color = c;
    canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w, h), paint);
  }

  if (d.kind == BodyKind.belt) {
    for (var n = 0; n < 14; n++) {
      final a = n * 2.39 + tick * 0.002;
      final rr = r * (0.4 + ((seed >> n) % 60) / 100);
      final s = math.max(1.0, (r / 7).roundToDouble() + n % 3);
      rect(cx + math.cos(a) * rr, cy + math.sin(a) * rr * 0.5, s, s, colors[n % 2]);
    }
    return;
  }
  final ringH = math.max(1.0, (r * 0.24).roundToDouble());
  if (d.kind == BodyKind.ring) rect(cx - r * 1.7, cy - ringH / 2, r * 3.4, ringH, colors[1]);
  if (d.kind == BodyKind.star) {
    paint.color = colors[1].withAlpha(64);
    canvas.drawCircle(center, r * 1.4, paint);
  }
  for (var yy = -r; yy <= r; yy++) {
    final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
    if (hw <= 0) continue;
    var c = colors[0];
    final yi = yy.toInt();
    if (d.kind == BodyKind.gas) {
      c = colors[((yy + r) ~/ math.max(2, r / 4)) % colors.length];
    } else if (d.kind == BodyKind.earth && (yi * 7 + seed) % 9 < 3) {
      c = colors[1];
    } else if (d.kind == BodyKind.rocky && (yi + seed) % 6 == 0) {
      c = colors[1];
    }
    rect(cx - hw, cy + yy, hw * 2, 1, c);
  }
  if (d.kind == BodyKind.moon || d.kind == BodyKind.rocky) {
    final s = math.max(1.0, (r / 6).roundToDouble());
    for (var n = 0; n < 6; n++) {
      final a = ((seed >> (n * 3)) % 628) / 100;
      final rr = r * (((seed >> (n * 2)) % 70) / 100);
      rect(cx + math.cos(a) * rr, cy + math.sin(a) * rr, s, s, colors[1]);
    }
  }
  if (d.kind == BodyKind.ring) {
    rect(cx - r * 1.7, cy - ringH / 2, r * 0.9, ringH, colors[1]);
    rect(cx + r * 0.8, cy - ringH / 2, r * 0.9, ringH, colors[1]);
  }
  paint.color = const Color(0x5916161D);
  for (var yy = -r; yy <= r; yy++) {
    final hw = math.sqrt(math.max(0, r * r - yy * yy)).floorToDouble();
    if (hw > 0) canvas.drawRect(Rect.fromLTWH((cx + hw * 0.35).roundToDouble(), cy + yy, hw * 0.65, 1), paint);
  }
}

/// Miniatura de item da loja num quadro 60x48.
void paintShopThumb(Canvas canvas, ShopItem it, int tick) {
  final p = Paint()..color = _ink;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 60, 48), p);
  switch (it.category) {
    case 'skin' || 'look':
      final eq = <String, String>{it.slot: it.id};
      paintGrid(canvas, astronautGrid(rank: 0, mk: 1, equipped: eq, tick: tick), const Offset(30 - 13 * 1.4, 1), 1.4);
    case 'pet':
      canvas.save();
      canvas.scale(3);
      paintPet(canvas, it.id, const Offset(5, 4), tick);
      canvas.restore();
    case 'magic':
      final c = Color(it.color!);
      for (var i = 0; i < 26; i++) {
        final a = i * 0.9, rr = 6 + (i % 5) * 3.4;
        p.color = i % 3 == 0 ? Kanagawa.fujiWhite : c;
        canvas.drawRect(Rect.fromLTWH((30 + math.cos(a) * rr * 1.4).roundToDouble(), (24 + math.sin(a) * rr).roundToDouble(), 2, 2), p);
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..color = c
        ..strokeWidth = it.id == 'mg_portal' ? 2 : 1;
      if (it.id == 'mg_portal') canvas.drawOval(const Rect.fromLTWH(18, 6, 24, 36), stroke);
      if (it.id == 'mg_halo') canvas.drawOval(const Rect.fromLTWH(16, 20, 28, 8), stroke);
    case 'power':
      final c = Color(it.color!);
      p.color = c;
      canvas.drawRect(const Rect.fromLTWH(18, 8, 24, 32), p);
      p.color = _ink;
      canvas.drawRect(const Rect.fromLTWH(22, 12, 16, 24), p);
      p.color = c;
      final shapes = switch (it.id) {
        'pw_boost' => const [Rect.fromLTWH(28, 14, 4, 20), Rect.fromLTWH(22, 22, 16, 4)],
        'pw_magnet' => const [Rect.fromLTWH(24, 14, 4, 16), Rect.fromLTWH(32, 14, 4, 16), Rect.fromLTWH(24, 26, 12, 4)],
        'pw_shield' => const [Rect.fromLTWH(24, 14, 12, 14), Rect.fromLTWH(27, 28, 6, 5)],
        _ => const [Rect.fromLTWH(28, 14, 4, 10), Rect.fromLTWH(24, 22, 8, 4), Rect.fromLTWH(28, 26, 4, 8)],
      };
      for (final s in shapes) {
        canvas.drawRect(s, p);
      }
  }
}

/// Foguete decolando (tela de carregamento), num quadro 160x90.
void paintLaunch(Canvas canvas, double progress, int tick) {
  final p = Paint()..color = _ink;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 160, 90), p);
  for (var i = 0; i < 40; i++) {
    p.color = i % 4 == 0 ? Kanagawa.carpYellow : Kanagawa.fujiWhite;
    final y = ((i * 23) + progress * 400 * (1 + i % 3)) % 90;
    canvas.drawRect(Rect.fromLTWH(((i * 37) % 160).toDouble(), y, 1, i % 5 == 0 ? 3 : 1), p);
  }
  final ry = 70 - progress * 30 + math.sin(progress * 40);
  void r(double a, double b, double w, double h, Color c) {
    p.color = c;
    canvas.drawRect(Rect.fromLTWH(74 + a, ry + b, w, h), p);
  }

  r(2, -16, 8, 22, _ink);
  r(3, -15, 6, 20, Kanagawa.fujiWhite);
  r(4, -19, 4, 4, Kanagawa.autumnRed);
  r(4, -8, 4, 4, Kanagawa.waveBlue1);
  r(5, -7, 2, 2, Kanagawa.springBlue);
  r(-1, 0, 4, 7, Kanagawa.autumnRed);
  r(9, 0, 4, 7, Kanagawa.autumnRed);
  final fl = 6.0 + (tick % 5);
  r(4, 6, 4, fl, Kanagawa.surimiOrange);
  r(5, 6, 2, fl - 2, Kanagawa.carpYellow);
}
