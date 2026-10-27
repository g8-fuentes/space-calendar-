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

  /// Avisos de transformação nova e de lugar novo quando o jogo avança.
  static List<Notice> progressNotices(GameState s, GameStats t) => [..._formNotices(s, t), ..._placeNotices(s, t)];

  static List<Notice> _formNotices(GameState s, GameStats t) {
    if (s.lastForm < 0 || t.formIndex < s.lastForm) {
      s.lastForm = t.formIndex;
      return const [];
    }
    if (t.formIndex == s.lastForm) return const [];
    s.lastForm = t.formIndex;
    final f = t.form;
    return [Notice('NOVA BÊNÇÃO!', '${f.title}\n\n"${f.passage.text}"\n${f.passage.ref}', form: f.index)];
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
            Region.solar => 'RUMO AO ESPAÇO!',
            Region.deep => 'ALÉM DO SISTEMA SOLAR!',
            Region.earth => 'NOVO DESTINO',
          }
        : 'NOVO DESTINO';
    return [
      Notice(title, 'Você chegou a ${p.name}. ${p.fact}', place: p.index),
    ];
  }
}
