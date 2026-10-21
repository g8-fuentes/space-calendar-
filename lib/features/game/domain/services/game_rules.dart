import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../catalog/catalog.dart';
import '../catalog/destinations.dart';
import '../entities/game_state.dart';
import 'game_stats.dart';

/// Aviso grande (janela) que a interface mostra depois de uma ação.
class Notice {
  const Notice(this.title, this.text, {this.enemyLevel, this.sound = 'lvl'});
  final String title;
  final String text;

  /// Mostra o inimigo deste nível na janela.
  final int? enemyLevel;
  final String sound;
}

/// Regras do jogo. Cada função muda o [GameState] recebido (uma cópia
/// feita pelo controlador) e devolve o que a interface precisa mostrar.
abstract final class GameRules {
  /// Marca ou desmarca a missão [m] no dia [day] da semana atual.
  /// Devolve o registro criado, ou null quando desmarcou.
  static DoneRecord? toggle(GameState s, Mission m, int day, DateTime now) {
    final w = s.week(weekKeyOf(now));
    final k = slotKey(m, day);
    final old = w.done.remove(k);
    if (old != null) {
      if (old.boost) s.boostCharges++;
      if (old.magnet) s.magnetCharges++;
      return null;
    }
    final rec = _record(s, m, day, now);
    w.done[k] = rec;
    return rec;
  }

  static DoneRecord _record(GameState s, Mission m, int day, DateTime now) {
    final base = questXp(m);
    final boost = s.boostCharges > 0, magnet = s.magnetCharges > 0;
    if (boost) s.boostCharges--;
    if (magnet) s.magnetCharges--;
    return DoneRecord(
      xp: (base * (boost ? 1.5 : 1)).round(),
      coins: questCoins(base) * (magnet ? 2 : 1),
      day: day,
      category: m.category,
      title: m.title,
      at: now.millisecondsSinceEpoch,
      courseId: m.link,
      boost: boost,
      magnet: magnet,
    );
  }

  /// Marca todas as missões de hoje que já começaram. Devolve quantas.
  static int markPastToday(GameState s, DateTime now) {
    final day = dayIndexOf(now), mm = minutesOfDay(now);
    final w = s.week(weekKeyOf(now));
    var n = 0;
    for (final m in daySlots(s, day)) {
      final st = minutesOf(m.start);
      final k = slotKey(m, day);
      if ((st == null || st <= mm) && !w.done.containsKey(k)) {
        w.done[k] = _record(s, m, day, now);
        n++;
      }
    }
    return n;
  }

  static void saveMission(GameState s, Mission data, {required bool isNew}) {
    data.days.sort();
    if (isNew) {
      s.missions.add(data);
      return;
    }
    final i = s.missions.indexWhere((m) => m.id == data.id);
    if (i >= 0) s.missions[i] = data;
  }

  static void deleteMission(GameState s, String id) => s.missions.removeWhere((m) => m.id == id);

  /// Soma ([replace] = false) ou troca as missões importadas. Missões com
  /// mesmo nome e horário não se repetem. Devolve quantas entraram.
  static int applyImport(GameState s, List<Mission> list, {required bool replace}) {
    if (replace) {
      s.missions = list;
      return list.length;
    }
    final keys = {for (final m in s.missions) _keyOf(m)};
    var n = 0;
    for (final m in list) {
      if (keys.add(_keyOf(m))) {
        s.missions.add(m);
        n++;
      }
    }
    return n;
  }

  static String _keyOf(Mission m) => '${norm(m.title)}|${m.start}|${m.end}';

  // ---------- Cursos e idiomas ----------

  static Course saveCourse(
    GameState s, {
    required String? id,
    required String name,
    required String kind,
    required int? total,
    required Set<String> linkedMissionIds,
  }) {
    Course target;
    if (id == null) {
      target = Course(
          id: uid(), name: name, kind: kind, color: colorCycle[s.courses.length % colorCycle.length], total: total);
      s.courses.add(target);
    } else {
      target = s.course(id)!;
      target.name = name;
      target.total = total;
      if (total != null && target.lessons > total) target.lessons = total;
    }
    for (final m in s.missions) {
      if (linkedMissionIds.contains(m.id)) {
        m.link = target.id;
      } else if (m.link == target.id) {
        m.link = null;
      }
    }
    return target;
  }

  static void deleteCourse(GameState s, String id) {
    s.courses.removeWhere((c) => c.id == id);
    for (final m in s.missions) {
      if (m.link == id) m.link = null;
    }
  }

  /// Um curso por linha; "Nome; 40" informa o total de aulas.
  static int bulkAddCourses(GameState s, String text, String kind) {
    final have = {for (final c in s.courses) '${c.kind}|${norm(c.name)}'};
    var n = 0;
    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final parts = lines[i].split(RegExp(r'[;\t]|,(?=\s*\d+\s*$)'));
      var name = parts.first
          .replaceFirst(RegExp(r'''^["'\s\-•*\d.)]+(?=\D)'''), '')
          .replaceAll(RegExp(r'''["']'''), '')
          .trim();
      if (name.isEmpty) continue;
      if (i == 0 && RegExp(r'^(curso|nome|course|name|titulo)s?$').hasMatch(norm(name))) continue;
      final tot = parts.length > 1 ? int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '')) : null;
      final key = '$kind|${norm(name)}';
      if (!have.add(key)) continue;
      if (name.length > 60) name = name.substring(0, 60);
      s.courses.add(Course(
        id: uid(),
        name: name,
        kind: kind,
        color: colorCycle[s.courses.length % colorCycle.length],
        total: kind == 'course' && tot != null && tot > 0 ? tot : null,
      ));
      n++;
    }
    return n;
  }

  /// +1 ou -1 aula. Devolve true se o curso acabou de ser concluído.
  static bool lesson(GameState s, String id, int delta) {
    final c = s.course(id);
    if (c == null) return false;
    if (delta > 0) {
      if (c.total != null && c.lessons >= c.total!) return false;
      c.lessons++;
      if (c.total != null && c.lessons >= c.total! && !c.finished) {
        c.finished = true;
        return true;
      }
    } else {
      if (c.lessons <= 0) return false;
      c.lessons--;
      if (c.total != null && c.lessons < c.total! && c.finished) c.finished = false;
    }
    return false;
  }

  static void finishCourse(GameState s, String id) => s.course(id)?.finished = true;

  static void reopenCourse(GameState s, String id) {
    final c = s.course(id);
    if (c == null) return;
    c.finished = false;
    if (c.total != null && c.lessons >= c.total!) c.lessons = c.total! - 1;
  }

  // ---------- Baú semanal ----------

  static bool chestReady(GameState s, String key, DateTime now) =>
      key.compareTo(weekKeyOf(now)) < 0 || weekStatsOf(s, key).ratio >= 1;

  static Chest? openChest(GameState s, String key, DateTime now) {
    final t = tierFor(weekStatsOf(s, key).ratio);
    if (t == null || !chestReady(s, key, now)) return null;
    final w = s.week(key);
    if (w.chest != null) return null;
    String? item;
    final notOwned = shopItems.where((c) => !c.isPower && !s.owned.contains(c.id) && c.price <= 400).toList();
    if (t.key != 'bronze' && notOwned.isNotEmpty) {
      var h = 7;
      for (final ch in key.codeUnits) {
        h = (h * 31 + ch) & 0xFFFFFFFF;
      }
      item = notOwned[h % notOwned.length].id;
    }
    final chest = Chest(tier: t.key, coins: t.coins, xp: t.xp, item: item);
    w.chest = chest;
    if (item != null && !s.owned.contains(item)) s.owned.add(item);
    return chest;
  }

  // ---------- Loja ----------

  static void _spend(GameState s, String id, String name, int price, DateTime now) =>
      s.purchases.add(Purchase(id: id, name: name, price: price, at: now.millisecondsSinceEpoch));

  static bool buyCosmetic(GameState s, ShopItem it, int coins, DateTime now) {
    if (coins < it.price || s.owned.contains(it.id)) return false;
    s.owned.add(it.id);
    _spend(s, it.id, it.name, it.price, now);
    s.equipped[it.slot] = it.id;
    return true;
  }

  /// Equipa ou tira. Devolve true se ficou equipado.
  static bool toggleEquip(GameState s, ShopItem it) {
    if (s.equipped[it.slot] == it.id) {
      s.equipped.remove(it.slot);
      return false;
    }
    s.equipped[it.slot] = it.id;
    return true;
  }

  static bool buyPower(GameState s, ShopItem it, int coins, DateTime now) {
    if (coins < it.price) return false;
    _spend(s, it.id, it.name, it.price, now);
    switch (it.id) {
      case 'pw_boost':
        s.boostCharges += 5;
      case 'pw_magnet':
        s.magnetCharges += 5;
      case 'pw_shield':
        s.shields++;
      case 'pw_hyper':
        s.bonusXp += 150;
    }
    return true;
  }

  static bool buyUpgrade(GameState s, Upgrade u, int coins, DateTime now) {
    final lvl = s.upgradeLevel(u.id), c = u.cost(lvl);
    if (coins < c) return false;
    _spend(s, u.id, '${u.name} nível ${lvl + 1}', c, now);
    s.upgrades[u.id] = lvl + 1;
    return true;
  }

  static bool redeemReward(GameState s, Reward r, int coins, DateTime now) {
    if (coins < r.price) return false;
    _spend(s, r.id, r.name, r.price, now);
    return true;
  }

  static void addReward(GameState s, String name, int price) =>
      s.rewards = [...s.rewards, Reward(id: uid(), name: name, price: price)];

  static void removeReward(GameState s, String id) => s.rewards = s.rewards.where((r) => r.id != id).toList();

  /// Avisos de progresso (nível, rank, traje, modo, inimigo, destino).
  /// Atualiza as marcas "último visto" no estado.
  static List<Notice> progressNotices(GameState s, GameStats t) {
    final out = <Notice>[];
    final name = s.name.isEmpty ? 'Astronauta' : s.name;
    final ri = t.rankIndex;
    if (!t.modeUnlocked(suitModes[s.suitMode])) s.suitMode = 0;
    if (t.lv > s.lastLevel) {
      final old = s.lastLevel;
      s.lastLevel = t.lv;
      var msg = '$name chegou ao nível ${t.lv}.';
      var promoted = false;
      if (ri > s.lastRank) {
        s.lastRank = ri;
        promoted = true;
        msg = 'Promoção! $name agora é ${t.rank.name}.';
      }
      if (suitMkFor(t.lv) > suitMkFor(old)) msg += ' Traje Mk ${suitMkFor(t.lv)} equipado.';
      final unlocked = suitModes.where((m) => m.id > 0 && t.modeUnlocked(m)).map((m) => m.id);
      final newest = unlocked.isEmpty ? 0 : unlocked.last;
      if (newest > s.lastModeSeen) {
        s.lastModeSeen = newest;
        msg += ' Novo modo do traje: ${suitModes[newest].name}.';
      }
      msg += ' Um novo inimigo surgiu no horizonte: ${t.enemy.name}.';
      out.add(Notice(promoted ? 'NOVO RANK!' : 'LEVEL UP!', msg, enemyLevel: t.lv));
    } else if (t.lv < s.lastLevel) {
      s.lastLevel = t.lv;
      s.lastRank = ri;
    }
    if (t.destinationIndex > s.lastDestination) {
      s.lastDestination = t.destinationIndex;
      final d = destinationAt(t.destinationIndex);
      out.add(Notice('CHEGOU EM ${d.name.toUpperCase()}!',
          '${d.fact} Próximo destino: ${destinationAt(t.destinationIndex + 1).name}.',
          sound: 'chest'));
    } else if (t.destinationIndex < s.lastDestination) {
      s.lastDestination = t.destinationIndex;
    }
    return out;
  }
}
