import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/places.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../widgets/explore_scene.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';
import 'settings_screen.dart' show exportHelp;

/// Primeira tela: nome, profissão e a agenda (.ics ou .ical).
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

  Future<void> _start() async {
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
    final err = await importCalendar(context, ref, heroName: n);
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
                Text('DEV ROUTINE',
                    textAlign: TextAlign.center, style: PixelText.display(16, color: Kanagawa.carpYellow)),
                const SizedBox(height: 4),
                Text('Sua agenda vira uma jornada no terminal, e você é o dev subindo de nível dentro da Matrix.',
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
                      decoration: pixelInput('Seu nome', hint: 'Ex.: Gui'),
                      onSubmitted: (_) => _start(),
                    ),
                    const SizedBox(height: 8),
                    PixelButton(label: 'Importar agenda (.ics ou .ical)', onPressed: _busy ? null : _start),
                    ErrorText(_error),
                    const SizedBox(height: 14),
                    Container(
                      color: Kanagawa.sumiInk0,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '$exportHelp\n\n'
                        'Cada evento com horário vira uma missão semanal.\n\n'
                        'Cada semana o dev entra num destino novo: começa na pasta ~ da sua máquina, passa pela '
                        'rede e pela nuvem e termina dentro da Matrix, sem fim. Cumpra metade das missões da '
                        'semana para explorar o destino e entrar no próximo na segunda-feira.',
                        style: PixelText.body(14, color: Kanagawa.springViolet1),
                      ),
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
