import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/discipline_flame.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Tarefas do dia: anotar, editar, excluir e marcar como concluída. Cada
/// tarefa concluída dá pontos de Disciplina e alimenta a chama.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final ctrl = ref.read(gameControllerProvider.notifier);
    if (ctrl.apply((s) => GameRules.addTodo(s, _text.text))) {
      Sfx.click.play();
      _text.clear();
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final today = ymd(ref.read(gameControllerProvider.notifier).now);
    final pending = s.todos.where((x) => !x.done).toList();
    // concluídas de outros dias somem da lista (os pontos continuam)
    final doneToday = s.todos
        .where((x) => x.done && ymd(DateTime.fromMillisecondsSinceEpoch(x.doneAt!)) == today)
        .toList()
      ..sort((a, b) => b.doneAt!.compareTo(a.doneAt!));
    final points = t.attributes['disciplina'] ?? 0;
    return ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 32), children: [
      PixelPanel(
        child: Row(children: [
          SizedBox(width: 92, height: 120, child: DisciplineFlame(level: t.flame)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DISCIPLINA', style: PixelText.display(10, color: Kanagawa.surimiOrange)),
              const SizedBox(height: 4),
              Text('$points pontos', style: PixelText.display(12)),
              const SizedBox(height: 4),
              Text('Chama ${flameLabel(t.flame)}', style: PixelText.body(16, color: Kanagawa.carpYellow)),
              const SizedBox(height: 6),
              Text(
                  'Cada tarefa concluída dá $todoPoints pontos de Disciplina. A chama cresce com as tarefas dos '
                  'últimos 7 dias e vai baixando se você parar.',
                  style: PixelText.body(13, color: Kanagawa.springViolet1)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('O QUE FAZER HOJE', style: PixelText.display(10)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                maxLength: 120,
                style: PixelText.body(16),
                textInputAction: TextInputAction.done,
                decoration: pixelInput('Nova tarefa', hint: 'Ex.: pagar a conta de luz').copyWith(counterText: ''),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            PixelButton(label: 'Adicionar', sound: false, onPressed: _add),
          ]),
          const SizedBox(height: 14),
          if (pending.isEmpty && doneToday.isEmpty)
            Text('Nenhuma tarefa ainda. Anote acima o que você precisa fazer hoje.',
                style: PixelText.body(14, color: Kanagawa.springViolet1)),
          for (final x in pending) _TodoRow(todo: x),
          if (doneToday.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('CONCLUÍDAS HOJE', style: PixelText.display(7, color: Kanagawa.springViolet1)),
            const SizedBox(height: 6),
            for (final x in doneToday) _TodoRow(todo: x),
          ],
        ]),
      ),
    ]);
  }
}

class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.todo});
  final Todo todo;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: todo.text);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Kanagawa.sumiInk4,
        shape: const RoundedRectangleBorder(side: BorderSide(color: Kanagawa.sumiInk0, width: 4)),
        title: Text('EDITAR TAREFA', style: PixelText.display(10)),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 120,
          style: PixelText.body(16),
          decoration: pixelInput('Tarefa').copyWith(counterText: ''),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          PixelButton(
              label: 'Cancelar',
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              onPressed: () => Navigator.of(ctx).pop()),
          PixelButton(label: 'Salvar', onPressed: () => Navigator.of(ctx).pop(c.text)),
        ],
      ),
    );
    c.dispose();
    if (text != null && text.trim().isNotEmpty) {
      ref.read(gameControllerProvider.notifier).apply((s) => GameRules.editTodo(s, todo.id, text));
      Sfx.save.play();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = todo.done;
    final ctrl = ref.read(gameControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        checked: done,
        label: todo.text,
        child: Material(
          color: Kanagawa.sumiInk5,
          child: InkWell(
            onTap: () {
              final marked = ctrl.apply((s) => GameRules.toggleTodo(s, todo.id, ctrl.now));
              if (marked) {
                Sfx.done.play();
                showToast(context, '+$todoPoints Disciplina');
              } else {
                Sfx.undo.play();
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Kanagawa.surimiOrange, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
              child: Row(children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? Kanagawa.springGreen : Kanagawa.sumiInk0,
                    border: Border.all(color: done ? Kanagawa.sumiInk0 : Kanagawa.springViolet1, width: 2),
                  ),
                  child: done ? const Icon(Icons.check, size: 14, color: Kanagawa.sumiInk0) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: done ? .6 : 1,
                    child: Text(todo.text,
                        style: PixelText.body(17)
                            .copyWith(decoration: done ? TextDecoration.lineThrough : null, decorationThickness: 2)),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Kanagawa.springViolet1),
                  onPressed: () => _edit(context, ref),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline, size: 20, color: Kanagawa.sakuraPink),
                  onPressed: () {
                    ctrl.apply((s) => GameRules.deleteTodo(s, todo.id));
                    Sfx.delete.play();
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
