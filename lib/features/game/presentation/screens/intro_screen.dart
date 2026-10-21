import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/space_scene.dart';
import '../widgets/ui.dart';

/// Tela inicial: nome do astronauta e de onde vêm as missões.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  late final _name = TextEditingController(text: ref.read(gameControllerProvider).name);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validName() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Escreva o nome do astronauta antes de continuar.');
      Sfx.error.play();
      return null;
    }
    setState(() => _error = null);
    return n;
  }

  Future<void> _import() async {
    final n = _validName();
    if (n == null) return;
    final err = await importCalendar(context, ref, ImportMode.intro, astronautName: n);
    if (err != null && mounted) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: PixelPanel(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('ROTINA QUEST',
                      textAlign: TextAlign.center,
                      style: PixelText.display(22, color: Kanagawa.carpYellow).copyWith(
                        shadows: const [Shadow(color: Kanagawa.sumiInk0, offset: Offset(3, 3))],
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Sua agenda vira uma jornada pelo espaço. Cada compromisso da semana é uma missão que dá XP e moedas.',
                    textAlign: TextAlign.center,
                    style: PixelText.body(16, color: Kanagawa.springViolet1),
                  ),
                  const SizedBox(height: 16),
                  const IntroScene(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    maxLength: 32,
                    textCapitalization: TextCapitalization.words,
                    style: PixelText.body(17),
                    decoration: pixelInput('Nome do astronauta', hint: 'Ex.: Ana Souza'),
                    onSubmitted: (_) => _import(),
                  ),
                  const SizedBox(height: 8),
                  PixelButton(label: 'Importar calendário', onPressed: _import),
                  const SizedBox(height: 10),
                  PixelButton(
                    label: 'Usar agenda de exemplo',
                    color: Kanagawa.sumiInk5,
                    textColor: Kanagawa.fujiWhite,
                    onPressed: () {
                      final n = _validName();
                      if (n != null) startDemo(context, ref, n);
                    },
                  ),
                  const SizedBox(height: 10),
                  PixelButton(
                    label: 'Começar sem calendário',
                    color: Kanagawa.sumiInk5,
                    textColor: Kanagawa.fujiWhite,
                    onPressed: () {
                      final n = _validName();
                      if (n != null) startEmpty(ref, n);
                    },
                  ),
                  ErrorText(_error),
                  const SizedBox(height: 14),
                  Container(
                    color: Kanagawa.sumiInk0,
                    padding: const EdgeInsets.all(12),
                    child: Text.rich(
                      TextSpan(style: PixelText.body(14, color: Kanagawa.springViolet1), children: [
                        TextSpan(text: 'Formatos aceitos: ', style: PixelText.body(14)),
                        const TextSpan(
                            text: '.ics, .cal e .csv. Os eventos viram missões que se repetem toda semana, no mesmo dia e horário.\n\n'),
                        TextSpan(text: 'Google Agenda: ', style: PixelText.body(14)),
                        const TextSpan(
                            text: 'no computador, Configurações › Importar e exportar › Exportar. Descompacte o .zip e envie o arquivo .ics para o celular.\n\n'),
                        TextSpan(text: 'CSV: ', style: PixelText.body(14)),
                        const TextSpan(text: 'colunas título, dia (seg, ter...) ou data, início e fim. Ex.: Academia;seg/qua;12:00;13:00'),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
