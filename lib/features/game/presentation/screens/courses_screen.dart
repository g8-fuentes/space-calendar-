import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Cursos (livres) e idiomas (lista própria, com nível A1–C2).
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final courses = s.courses.where((c) => !c.isLanguage).toList();
    final langs = s.courses.where((c) => c.isLanguage).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Header('CURSOS', [
            PixelButton(label: '+ Curso', dense: true, onPressed: () => openCourseForm(context, kind: 'course')),
            PixelButton(
                label: 'Importar lista',
                dense: true,
                color: Kanagawa.sumiInk5,
                textColor: Kanagawa.fujiWhite,
                onPressed: () => openSheet(context, (_) => const _BulkForm())),
          ]),
          const SizedBox(height: 8),
          Text(
            'Ligue um curso a uma ou mais missões. Quando você conclui a missão, o XP dela também vai para o curso. O número de aulas é opcional.',
            style: PixelText.body(14, color: Kanagawa.springViolet1),
          ),
          const SizedBox(height: 12),
          if (courses.isEmpty)
            const EmptyBox('Nenhum curso ainda.', 'Adicione um curso ou importe sua lista inteira de uma vez.')
          else
            for (final c in courses) ...[_CourseCard(course: c), const SizedBox(height: 10)],
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Header('IDIOMAS', [
            PixelButton(label: '+ Idioma', dense: true, onPressed: () => openCourseForm(context, kind: 'lang')),
          ]),
          const SizedBox(height: 8),
          Text('Idiomas têm lista própria: nível de A1 a C2 pelo XP e uma sequência de dias seguidos de estudo.',
              style: PixelText.body(14, color: Kanagawa.springViolet1)),
          const SizedBox(height: 12),
          if (langs.isEmpty)
            const EmptyBox('Nenhum idioma ainda.', 'Adicione um idioma e ligue a ele as missões de aula ou de app de idiomas.')
          else
            for (final c in langs) ...[_LanguageCard(course: c), const SizedBox(height: 10)],
        ]),
      ),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, this.actions);
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 8,
        children: [
          Text(title, style: PixelText.display(11)),
          Wrap(spacing: 8, children: actions),
        ],
      );
}

List<Widget> _missionChips(GameState s, Course c) {
  final linked = s.missions.where((m) => m.link == c.id).toList();
  if (linked.isEmpty) return [const TagChip('Nenhuma missão ligada', off: true)];
  return [
    for (final m in linked)
      TagChip('${m.title} · ${m.days.map((d) => dayAbbr[d]).join(' ')}', color: Color(categoryOf(m.category).color)),
  ];
}

void _lesson(BuildContext context, WidgetRef ref, Course c, int delta) {
  final ctrl = ref.read(gameControllerProvider.notifier);
  final before = c.lessons;
  final finished = ctrl.apply((s) => GameRules.lesson(s, c.id, delta), burst: delta > 0 ? lessonXp : null);
  final after = ref.read(gameControllerProvider).course(c.id)?.lessons ?? before;
  if (after == before) return;
  if (delta > 0) {
    Sfx.lesson.play();
    if (finished) {
      ctrl.notify([Notice('CURSO CONCLUÍDO!', '${c.name} terminado. +$courseXp XP e +$courseCoins moedas.', sound: 'chest')]);
    } else {
      showToast(context, '+1 aula de ${c.name} · +$lessonXp XP');
    }
  } else {
    Sfx.undo.play();
    showToast(context, 'Aula desfeita em ${c.name}');
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final c = course;
    final xp = courseXpOf(s, c);
    final lv = xp ~/ courseLevelXp + 1, into = xp % courseLevelXp;
    final color = Color(c.color);
    final full = c.total != null && c.lessons >= c.total!;
    return PixelPanel(
      color: Kanagawa.sumiInk5,
      accent: color,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(c.name.toUpperCase(), style: PixelText.display(9).copyWith(height: 1.6))),
          if (c.finished)
            Container(
                padding: const EdgeInsets.all(5),
                color: Kanagawa.springGreen,
                child: Text('CONCLUÍDO', style: PixelText.display(6, color: Kanagawa.sumiInk0)))
          else
            Text('NV $lv', style: PixelText.display(7, color: Kanagawa.springBlue)),
        ]),
        const SizedBox(height: 8),
        PixelBar(value: into / courseLevelXp, color: color),
        const SizedBox(height: 4),
        Text('$xp XP no curso · $into/$courseLevelXp para o nível ${lv + 1}', style: PixelText.body(13, color: Kanagawa.springViolet1)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(c.total != null ? '${c.lessons}/${c.total} aulas' : 'Sem número de aulas definido',
                style: PixelText.body(13, color: Kanagawa.springViolet1)),
          ),
          if (c.total != null) ...[
            PixelButton(
                label: '−', dense: true, color: Kanagawa.sumiInk0, textColor: Kanagawa.fujiWhite, sound: false, onPressed: () => _lesson(context, ref, c, -1)),
            const SizedBox(width: 6),
          ],
          PixelButton(label: '+1 aula', dense: true, sound: false, onPressed: full ? null : () => _lesson(context, ref, c, 1)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _missionChips(s, c)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          PixelButton(
              label: 'Editar', dense: true, color: Kanagawa.sumiInk0, textColor: Kanagawa.fujiWhite, onPressed: () => openCourseForm(context, course: c)),
          if (c.finished)
            PixelButton(
              label: 'Reabrir',
              dense: true,
              color: Kanagawa.sumiInk0,
              textColor: Kanagawa.fujiWhite,
              sound: false,
              onPressed: () {
                ref.read(gameControllerProvider.notifier).apply((g) => GameRules.reopenCourse(g, c.id));
                Sfx.undo.play();
                showToast(context, '${c.name} reaberto');
              },
            )
          else
            PixelButton(
              label: 'Concluir curso',
              dense: true,
              color: Kanagawa.springBlue,
              sound: false,
              onPressed: () {
                final ctrl = ref.read(gameControllerProvider.notifier);
                ctrl.apply((g) => GameRules.finishCourse(g, c.id), burst: courseXp);
                ctrl.notify([Notice('CURSO CONCLUÍDO!', '${c.name} terminado. +$courseXp XP e +$courseCoins moedas.', sound: 'chest')]);
              },
            ),
        ]),
      ]),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final c = course;
    final xp = courseXpOf(s, c);
    final cf = cefrOf(xp);
    final streak = languageStreak(s, c.id, now);
    final color = Color(c.color);
    return PixelPanel(
      color: Kanagawa.sumiInk5,
      accent: color,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(c.name.toUpperCase(), style: PixelText.display(9).copyWith(height: 1.6))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: color,
              child: Text(cf.level, style: PixelText.display(11, color: Kanagawa.sumiInk0))),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$streak', style: PixelText.display(15, color: color)),
          const SizedBox(width: 6),
          Expanded(child: Text('dia${streak == 1 ? '' : 's'} seguidos', style: PixelText.body(13, color: Kanagawa.springViolet1))),
          Text('$xp XP', style: PixelText.body(13, color: Kanagawa.springViolet1)),
        ]),
        const SizedBox(height: 8),
        PixelBar(value: cf.need == 0 ? 1 : cf.into / cf.need, color: color),
        const SizedBox(height: 4),
        Text(cf.next != null ? '${cf.into}/${cf.need} XP para o nível ${cf.next}' : 'Nível máximo de fluência no jogo',
            style: PixelText.body(13, color: Kanagawa.springViolet1)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _missionChips(s, c)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('Aulas extras: ${c.lessons}', style: PixelText.body(13, color: Kanagawa.springViolet1))),
          PixelButton(
              label: '−', dense: true, color: Kanagawa.sumiInk0, textColor: Kanagawa.fujiWhite, sound: false, onPressed: () => _lesson(context, ref, c, -1)),
          const SizedBox(width: 6),
          PixelButton(label: '+1 aula', dense: true, sound: false, onPressed: () => _lesson(context, ref, c, 1)),
          const SizedBox(width: 6),
          PixelButton(
              label: 'Editar', dense: true, color: Kanagawa.sumiInk0, textColor: Kanagawa.fujiWhite, onPressed: () => openCourseForm(context, course: c)),
        ]),
      ]),
    );
  }
}

Future<void> openCourseForm(BuildContext context, {Course? course, String kind = 'course'}) =>
    openSheet(context, (_) => _CourseForm(course: course, kind: course?.kind ?? kind));

class _CourseForm extends ConsumerStatefulWidget {
  const _CourseForm({this.course, required this.kind});
  final Course? course;
  final String kind;

  @override
  ConsumerState<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends ConsumerState<_CourseForm> {
  late final bool isNew = widget.course == null;
  late final bool isLang = widget.kind == 'lang';
  late final _name = TextEditingController(text: widget.course?.name ?? '');
  late final _total = TextEditingController(text: widget.course?.total?.toString() ?? '');
  late final Set<String> _linked = {
    if (widget.course != null)
      for (final m in ref.read(gameControllerProvider).missions)
        if (m.link == widget.course!.id) m.id,
  };
  bool _confirm = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      Sfx.error.play();
      setState(() => _error = 'Dê um nome.');
      return;
    }
    final parsed = int.tryParse(_total.text.trim());
    final total = !isLang && parsed != null ? (parsed < 1 ? 1 : parsed) : null;
    ref.read(gameControllerProvider.notifier).apply((s) =>
        GameRules.saveCourse(s, id: widget.course?.id, name: n, kind: widget.kind, total: total, linkedMissionIds: _linked));
    Sfx.save.play();
    Navigator.of(context).pop();
    showToast(context, '${isNew ? 'Adicionado' : 'Salvo'}: $n');
  }

  void _delete() {
    final c = widget.course!;
    ref.read(gameControllerProvider.notifier).apply((s) => GameRules.deleteCourse(s, c.id));
    Sfx.delete.play();
    Navigator.of(context).pop();
    showToast(context, 'Excluído: ${c.name}');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameControllerProvider);
    final missions = [...s.missions]..sort((a, b) => a.title.compareTo(b.title));
    final title = isNew ? (isLang ? 'NOVO IDIOMA' : 'NOVO CURSO') : (isLang ? 'EDITAR IDIOMA' : 'EDITAR CURSO');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: PixelText.display(12, color: Kanagawa.carpYellow)),
      const SizedBox(height: 14),
      TextField(
        controller: _name,
        maxLength: 60,
        autofocus: isNew,
        style: PixelText.body(17),
        decoration: pixelInput(isLang ? 'Idioma' : 'Nome do curso', hint: isLang ? 'Ex.: Inglês' : 'Ex.: React avançado'),
      ),
      if (isLang)
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final l in languageSuggestions)
            InkWell(
              onTap: () {
                Sfx.click.play();
                setState(() => _name.text = l);
              },
              child: TagChip(l),
            ),
        ])
      else
        TextField(
          controller: _total,
          keyboardType: TextInputType.number,
          style: PixelText.body(17),
          decoration: pixelInput('Total de aulas (opcional)', hint: 'Deixe vazio se não souber'),
        ),
      const SizedBox(height: 14),
      Text('Missões ligadas a ${isLang ? 'este idioma' : 'este curso'}', style: PixelText.body(14, color: Kanagawa.springViolet1)),
      const SizedBox(height: 6),
      if (missions.isEmpty)
        Text('Você ainda não tem missões para ligar.', style: PixelText.body(14, color: Kanagawa.springViolet1))
      else
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          color: Kanagawa.sumiInk0,
          child: ListView(shrinkWrap: true, children: [
            for (final m in missions)
              CheckboxListTile(
                dense: true,
                value: _linked.contains(m.id),
                onChanged: (v) {
                  Sfx.click.play();
                  setState(() => v == true ? _linked.add(m.id) : _linked.remove(m.id));
                },
                title: Text(m.title, style: PixelText.body(15)),
                subtitle: Text(
                  '${m.days.map((d) => dayAbbr[d]).join(' ')} ${m.start}'
                  '${m.link != null && m.link != widget.course?.id ? ' · ligada a ${s.course(m.link)?.name ?? ''}' : ''}',
                  style: PixelText.body(12, color: Kanagawa.springViolet1),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ]),
        ),
      ErrorText(_error),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        PixelButton(label: 'Salvar', onPressed: _save, sound: false),
        PixelButton(label: 'Cancelar', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: () => Navigator.of(context).pop()),
        if (!isNew)
          PixelButton(label: 'Excluir', color: Kanagawa.autumnRed, textColor: Kanagawa.fujiWhite, onPressed: () => setState(() => _confirm = true)),
      ]),
      if (_confirm) ...[
        const SizedBox(height: 10),
        ConfirmBar(
          text: 'Excluir “${widget.course!.name}”? O XP já ganho continua no seu nível.',
          yesLabel: 'Sim, excluir',
          onYes: _delete,
          onNo: () => setState(() => _confirm = false),
        ),
      ],
    ]);
  }
}

class _BulkForm extends ConsumerStatefulWidget {
  const _BulkForm();

  @override
  ConsumerState<_BulkForm> createState() => _BulkFormState();
}

class _BulkFormState extends ConsumerState<_BulkForm> {
  final _text = TextEditingController();
  String _kind = 'course';
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final f = await pickTextFile();
      if (f != null) setState(() => _text.text = f.$2);
    } catch (_) {
      Sfx.error.play();
    }
  }

  void _save() {
    final n = ref.read(gameControllerProvider.notifier).apply((s) => GameRules.bulkAddCourses(s, _text.text, _kind));
    if (n == 0) {
      Sfx.error.play();
      setState(() => _error = 'Nenhum curso novo encontrado na lista.');
      return;
    }
    Sfx.save.play();
    Navigator.of(context).pop();
    showToast(context, '$n ${_kind == 'lang' ? 'idiomas adicionados' : 'cursos adicionados'}');
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('IMPORTAR LISTA DE CURSOS', style: PixelText.display(11, color: Kanagawa.carpYellow)),
        const SizedBox(height: 10),
        Text('Um curso por linha. Para informar o total de aulas, coloque um ponto e vírgula e o número. Também aceita arquivo .txt ou .csv.',
            style: PixelText.body(14, color: Kanagawa.springViolet1)),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 6,
          maxLines: 12,
          style: PixelText.body(16),
          decoration: pixelInput('Lista', hint: 'React avançado; 40\nFotografia digital\nExcel do zero; 25'),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PixelButton(label: 'Escolher arquivo', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: _pick),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _kind,
          decoration: pixelInput('Adicionar como'),
          dropdownColor: Kanagawa.sumiInk4,
          style: PixelText.body(16),
          items: const [
            DropdownMenuItem(value: 'course', child: Text('Cursos')),
            DropdownMenuItem(value: 'lang', child: Text('Idiomas')),
          ],
          onChanged: (v) => setState(() => _kind = v ?? 'course'),
        ),
        ErrorText(_error),
        const SizedBox(height: 14),
        Wrap(spacing: 10, children: [
          PixelButton(label: 'Adicionar todos', onPressed: _save, sound: false),
          PixelButton(label: 'Cancelar', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: () => Navigator.of(context).pop()),
        ]),
      ]);
}
