import '../../../../core/text/text_utils.dart';
import '../../../../core/time/week_utils.dart';
import '../catalog/places.dart';
import '../entities/game_state.dart';
import 'game_stats.dart';

/// Aviso grande (janela) que a interface mostra depois de uma ação.
class Notice {
  const Notice(this.title, this.text, {this.sound = 'lvl', this.place, this.form});
  final String title;
  final String text;
  final String sound;

  /// Mostra este lugar na janela.
  final int? place;

  /// Mostra o personagem nesta transformação.
  final int? form;
}

/// Regras do jogo. Cada função muda o [GameState] recebido (uma cópia
/// feita pelo controlador). O app só lê a agenda e marca o que foi feito.
abstract final class GameRules {
  /// Marca ou desmarca a missão [m] no dia [day] da semana atual.
  /// Devolve true quando marcou.
  static bool toggle(GameState s, Mission m, int day, DateTime now) {
    final w = s.week(weekKeyOf(now));
    final k = slotKey(m, day);
    if (w.done.remove(k) != null) return false;
    w.done[k] = _record(m, day, now);
    return true;
  }

  static DoneRecord _record(Mission m, int day, DateTime now) => DoneRecord(
      day: day, title: m.title, at: now.millisecondsSinceEpoch, category: m.category, minutes: missionMinutes(m));

  /// Marca todas as missões de hoje que já começaram. Devolve quantas.
  static int markPastToday(GameState s, DateTime now) {
    final day = dayIndexOf(now), mm = minutesOfDay(now);
    final w = s.week(weekKeyOf(now));
    var n = 0;
    for (final m in daySlots(s, day)) {
      final a = minutesOf(m.start);
      final k = slotKey(m, day);
      if (a != null && a <= mm && !w.done.containsKey(k)) {
        w.done[k] = _record(m, day, now);
        n++;
      }
    }
    return n;
  }

  /// Anota uma tarefa do dia. Devolve false se o texto estiver vazio.
  static bool addTodo(GameState s, String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    s.todos.add(Todo(id: uid(), text: t.length > 120 ? t.substring(0, 120) : t));
    return true;
  }

  static void editTodo(GameState s, String id, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    for (final x in s.todos) {
      if (x.id == id) x.text = t.length > 120 ? t.substring(0, 120) : t;
    }
  }

  /// Marca ou desmarca a tarefa. Devolve true quando marcou.
  static bool toggleTodo(GameState s, String id, DateTime now) {
    for (final x in s.todos) {
      if (x.id != id) continue;
      x.doneAt = x.done ? null : now.millisecondsSinceEpoch;
      return x.done;
    }
    return false;
  }

  /// Exclui a tarefa (e os pontos dela, se estava concluída).
  static void deleteTodo(GameState s, String id) => s.todos.removeWhere((x) => x.id == id);

  /// Troca as missões pelas da agenda importada. Missões que continuam
  /// na agenda mantêm o id, então o que já foi marcado continua marcado.
  static void importMissions(GameState s, List<Mission> list) {
    final old = {for (final m in s.missions) m.key: m};
    s.missions = [
      for (final m in list)
        if (old[m.key] case final prev?)
          Mission(id: prev.id, title: m.title, days: m.days, start: m.start, end: m.end, category: m.category)
        else
          m,
    ];
  }

  /// Guarda se a meta desta semana foi cumprida e devolve os avisos de
  /// transformação nova, destino explorado e destino novo.
  static List<Notice> progressNotices(GameState s, GameStats t) {
    if (t.weekKey.isNotEmpty) {
      if (t.explored) {
        s.explored.add(t.weekKey);
      } else {
        s.explored.remove(t.weekKey);
      }
    }
    return [..._formNotices(s, t), ..._exploredNotices(s, t), ..._placeNotices(s, t)];
  }

  static List<Notice> _formNotices(GameState s, GameStats t) {
    if (s.lastForm < 0 || t.formIndex < s.lastForm) {
      s.lastForm = t.formIndex;
      return const [];
    }
    if (t.formIndex == s.lastForm) return const [];
    s.lastForm = t.formIndex;
    final f = t.form;
    return [Notice('NOVO NÍVEL!', '${f.title}: ${f.description}', form: f.index)];
  }

  static List<Notice> _exploredNotices(GameState s, GameStats t) {
    if (!t.explored || t.weekKey.isEmpty || s.lastExplored == t.weekKey) return const [];
    s.lastExplored = t.weekKey;
    return [
      Notice('DESTINO EXPLORADO!',
          '${t.place.name}: meta da semana cumprida. Na segunda-feira a nave parte para ${t.next.name}.',
          place: t.place.index),
    ];
  }

  static List<Notice> _placeNotices(GameState s, GameStats t) {
    if (s.lastPlace < 0) {
      s.lastPlace = t.placeIndex;
      return const [];
    }
    if (t.placeIndex <= s.lastPlace) {
      if (t.placeIndex < s.lastPlace) s.lastPlace = t.placeIndex;
      return const [];
    }
    final from = placeAt(s.lastPlace);
    s.lastPlace = t.placeIndex;
    final p = t.place;
    final title = p.region != from.region
        ? switch (p.region) {
            Region.stars => 'ALÉM DO SISTEMA SOLAR!',
            Region.galaxy => 'RUMO À GALÁXIA!',
            Region.solar => 'NOVO DESTINO',
          }
        : 'NOVO DESTINO';
    return [
      Notice(title, 'Semana ${p.week}: ${p.name}. ${p.fact}', place: p.index),
    ];
  }
}
