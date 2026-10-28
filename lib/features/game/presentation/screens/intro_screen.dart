import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/places.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../controllers/sync_flow.dart';
import '../widgets/explore_scene.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Primeira tela: nome do dev e a conexão com o Google Agenda (ou, como
/// alternativa, um arquivo .ics).
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  late final _name = TextEditingController(text: ref.read(gameControllerProvider).name);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start({required bool google}) async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Escreva o nome do personagem antes de continuar.');
      Sfx.error.play();
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final err =
        google ? await connectGoogle(context, ref, heroName: n) : await importCalendar(context, ref, heroName: n);
    if (mounted) {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('DEV ODYSSEY',
                    textAlign: TextAlign.center, style: PixelText.display(16, color: Kanagawa.carpYellow)),
                const SizedBox(height: 4),
                Text('Sua agenda vira a exploração espacial de um dev.',
                    textAlign: TextAlign.center, style: PixelText.body(16, color: Kanagawa.springViolet1)),
                const SizedBox(height: 14),
                PixelPanel(padding: EdgeInsets.zero, child: ExploreScene(placeOverride: placeAt(0))),
                const SizedBox(height: 16),
                PixelPanel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextField(
                      controller: _name,
                      maxLength: 24,
                      style: PixelText.body(17),
                      decoration: pixelInput('Nome do dev', hint: 'Ex.: Gui'),
                      onSubmitted: (_) => _start(google: true),
                    ),
                    const SizedBox(height: 8),
                    PixelButton(label: 'Conectar Google Agenda', onPressed: _busy ? null : () => _start(google: true)),
                    ErrorText(_error),
                    const SizedBox(height: 14),
                    Container(
                      color: Kanagawa.sumiInk0,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'O app lê (sem mudar nada) os eventos com horário da semana no seu Google Agenda, e eles '
                        'viram missões. A agenda atualiza sozinha toda vez que você abre o app.\n\n'
                        'Cada semana o dev explora um destino: começa na Terra, passa pela Lua e pelos planetas e '
                        'depois sai do Sistema Solar rumo às estrelas e às galáxias. Cumpra metade das missões da '
                        'semana para explorar o destino e partir para o próximo na segunda-feira.',
                        style: PixelText.body(14, color: Kanagawa.springViolet1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy ? null : () => _start(google: false),
                      child: Text('Sem Google? Importar arquivo .ics',
                          style: PixelText.body(14, color: Kanagawa.springBlue)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
