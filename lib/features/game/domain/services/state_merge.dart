import '../entities/game_state.dart';

/// Junta dois saves do mesmo jogador (por exemplo, o do celular e o da
/// nuvem) sem perder nada: missões concluídas, dias pulados, semanas
/// exploradas e tarefas dos dois lados ficam.
///
/// [newer] é o save editado por último: dele vêm as opções (tema, sons,
/// nome) e a ordem das missões. Missões iguais (mesmo título e horário)
/// com ids diferentes viram uma só, e as conclusões de [older] passam a
/// apontar para o id de [newer].
GameState mergeStates(GameState newer, GameState older) {
  final out = newer.copy();
  final src = older.copy();

  // Missões: as de [newer] e as que só existem em [older].
  final byKey = {for (final m in out.missions) m.key: m};
  final idMap = <String, String>{};
  for (final m in src.missions) {
    final same = byKey[m.key];
    if (same != null) {
      idMap[m.id] = same.id;
      same.days = ({...same.days, ...m.days}.toList()..sort());
    } else {
      out.missions.add(m);
      byKey[m.key] = m;
    }
  }

  String remap(String doneKey) {
    final at = doneKey.lastIndexOf('@');
    if (at < 0) return doneKey;
    final id = doneKey.substring(0, at);
    final mapped = idMap[id];
    return mapped == null ? doneKey : '$mapped${doneKey.substring(at)}';
  }

  // Semanas: une as conclusões e os dias pulados.
  for (final e in src.weeks.entries) {
    final w = out.week(e.key);
    for (final d in e.value.done.entries) {
      final k = remap(d.key);
      final mine = w.done[k];
      if (mine == null || (d.value.at > 0 && d.value.at < mine.at)) w.done[k] = d.value;
    }
    w.skipped.addAll(e.value.skipped);
  }

  out.explored.addAll(src.explored);

  // Tarefas: une por id; concluída num aparelho fica concluída.
  final todos = {for (final t in out.todos) t.id: t};
  for (final t in src.todos) {
    final mine = todos[t.id];
    if (mine == null) {
      out.todos.add(t);
    } else if (mine.doneAt == null && t.doneAt != null) {
      mine.doneAt = t.doneAt;
    }
  }

  out.onboarded = out.onboarded || src.onboarded;
  if (out.name.trim().isEmpty) out.name = src.name;
  if (src.startDate.isNotEmpty && (out.startDate.isEmpty || src.startDate.compareTo(out.startDate) < 0)) {
    out.startDate = src.startDate;
  }
  if (src.lastPlace > out.lastPlace) out.lastPlace = src.lastPlace;
  if (src.lastForm > out.lastForm) out.lastForm = src.lastForm;
  if (src.lastExplored.compareTo(out.lastExplored) > 0) out.lastExplored = src.lastExplored;
  return out;
}

/// Save sem nada do jogador (aparelho novo): pode ser trocado pelo da
/// nuvem sem juntar.
bool isPristine(GameState s) =>
    !s.onboarded && s.missions.isEmpty && s.todos.isEmpty && s.weeks.values.every((w) => w.done.isEmpty);
