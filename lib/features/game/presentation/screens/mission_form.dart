import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

Future<void> openMissionForm(BuildContext context, {Mission? mission, int? presetDay}) =>
    openSheet(context, (_) => MissionForm(mission: mission, presetDay: presetDay));

/// Criar ou editar uma missão (e excluir).
class MissionForm extends ConsumerStatefulWidget {
  const MissionForm({super.key, this.mission, this.presetDay});
  final Mission? mission;
  final int? presetDay;

  @override
  ConsumerState<MissionForm> createState() => _MissionFormState();
}

class _MissionFormState extends ConsumerState<MissionForm> {
  late final bool isNew = widget.mission == null;
  late final _title = TextEditingController(text: widget.mission?.title ?? '');
  late Set<int> _days = {...?widget.mission?.days, if (widget.mission == null) widget.presetDay ?? 0};
  late String _start = widget.mission?.start ?? '';
  late String _end = widget.mission?.end ?? '';
  late String _cat = widget.mission?.category ?? 'cuidado';
  late String? _link = widget.mission?.link;
  bool _catTouched = false;
  bool _confirm = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final cur = minutesOf(start ? _start : _end);
    final t = await showTimePicker(
      context: context,
      initialTime: cur == null ? const TimeOfDay(hour: 8, minute: 0) : TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    setState(() {
      final v = '${two(t.hour)}:${two(t.minute)}';
      if (start) {
        _start = v;
      } else {
        _end = v;
      }
    });
  }

  void _save() {
    final t = _title.text.trim();
    if (t.isEmpty) return _fail('Dê um nome para a missão.');
    if (_days.isEmpty) return _fail('Escolha pelo menos um dia da semana.');
    final m = Mission(
      id: widget.mission?.id ?? uid(),
      title: t,
      days: _days.toList()..sort(),
      start: _start,
      end: _end,
      category: _cat,
      link: _link,
    );
    ref.read(gameControllerProvider.notifier).apply((s) => GameRules.saveMission(s, m, isNew: isNew));
    Sfx.save.play();
    Navigator.of(context).pop();
    showToast(context, isNew ? 'Missão criada: $t' : 'Missão salva: $t');
  }

  void _fail(String msg) {
    Sfx.error.play();
    setState(() => _error = msg);
  }

  void _delete() {
    final id = widget.mission!.id;
    ref.read(gameControllerProvider.notifier).apply((s) => GameRules.deleteMission(s, id));
    Sfx.delete.play();
    Navigator.of(context).pop();
    showToast(context, 'Missão excluída');
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(gameControllerProvider.select((s) => s.courses));
    final xp = questXp(Mission(id: '', title: '', days: const [], start: _start, end: _end, category: _cat));
    final linkOk = courses.any((c) => c.id == _link);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(isNew ? 'NOVA MISSÃO' : 'EDITAR MISSÃO', style: PixelText.display(12, color: Kanagawa.carpYellow)),
      const SizedBox(height: 14),
      TextField(
        controller: _title,
        maxLength: 80,
        autofocus: isNew,
        style: PixelText.body(17),
        decoration: pixelInput('Nome da missão', hint: 'Ex.: Academia'),
        onChanged: (v) {
          if (isNew && !_catTouched) setState(() => _cat = guessCategory(v));
        },
      ),
      Text('Repete toda semana em', style: PixelText.body(14, color: Kanagawa.springViolet1)),
      const SizedBox(height: 6),
      DayPicker(selected: _days, onChanged: (d) => setState(() => _days = d)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _TimeField(label: 'Início', value: _start, onTap: () => _pickTime(true), onClear: () => setState(() => _start = ''))),
        const SizedBox(width: 10),
        Expanded(child: _TimeField(label: 'Fim', value: _end, onTap: () => _pickTime(false), onClear: () => setState(() => _end = ''))),
      ]),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: _cat,
        decoration: pixelInput('Categoria'),
        dropdownColor: Kanagawa.sumiInk4,
        style: PixelText.body(16),
        items: [for (final c in categories) DropdownMenuItem(value: c.key, child: Text(c.name))],
        onChanged: (v) => setState(() {
          _catTouched = true;
          _cat = v ?? _cat;
        }),
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String?>(
        initialValue: linkOk ? _link : null,
        decoration: pixelInput('Ligar a um curso ou idioma'),
        dropdownColor: Kanagawa.sumiInk4,
        style: PixelText.body(16),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('Nenhum')),
          for (final c in courses)
            DropdownMenuItem<String?>(value: c.id, child: Text('${c.isLanguage ? 'Idioma' : 'Curso'} · ${c.name}', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _link = v),
      ),
      const SizedBox(height: 10),
      Text('Vale $xp XP e ${questCoins(xp)} moedas por dia.', style: PixelText.body(14, color: Kanagawa.springViolet1)),
      ErrorText(_error),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        PixelButton(label: 'Salvar missão', onPressed: _save, sound: false),
        PixelButton(label: 'Cancelar', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: () => Navigator.of(context).pop()),
        if (!isNew)
          PixelButton(label: 'Excluir', color: Kanagawa.autumnRed, textColor: Kanagawa.fujiWhite, onPressed: () => setState(() => _confirm = true)),
      ]),
      if (_confirm) ...[
        const SizedBox(height: 10),
        ConfirmBar(
          text: 'Excluir “${widget.mission!.title}” de todos os dias?',
          yesLabel: 'Sim, excluir',
          onYes: _delete,
          onNo: () => setState(() => _confirm = false),
        ),
      ],
    ]);
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap, required this.onClear});
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: pixelInput(label).copyWith(
            suffixIcon: value.isEmpty
                ? const Icon(Icons.schedule, size: 18)
                : IconButton(icon: const Icon(Icons.close, size: 18), tooltip: 'Sem horário', onPressed: onClear),
          ),
          child: Text(value.isEmpty ? 'livre' : value,
              style: PixelText.body(17, color: value.isEmpty ? Kanagawa.springViolet1 : Kanagawa.fujiWhite)),
        ),
      );
}
