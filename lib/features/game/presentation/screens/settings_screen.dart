import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Passo a passo para tirar o arquivo .ics do Google Agenda.
const exportHelp = 'No computador, abra calendar.google.com, vá em Configurações > Importar e exportar > Exportar. '
    'Vem um .zip: descompacte e mande o arquivo .ics da sua agenda para o celular.';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name = TextEditingController(text: ref.read(gameControllerProvider).name);
  String? _importError;
  bool _confirmReset = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    return ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('AGENDA', style: PixelText.display(10)),
          const SizedBox(height: 6),
          Text(
            s.missions.isEmpty
                ? 'Nenhuma agenda importada ainda.'
                : '${s.missions.length} eventos da agenda viram missões toda semana.',
            style: PixelText.body(15),
          ),
          const SizedBox(height: 6),
          Text(exportHelp, style: PixelText.body(14, color: Kanagawa.springViolet1)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: PixelButton(
              label: s.missions.isEmpty ? 'Importar agenda (.ics ou .cal)' : 'Importar agenda atualizada',
              onPressed: () async {
                final err = await importCalendar(context, ref);
                if (mounted) setState(() => _importError = err);
              },
            ),
          ),
          ErrorText(_importError),
          const SizedBox(height: 6),
          Text('O progresso da jornada continua ao trocar a agenda.',
              style: PixelText.body(13, color: Kanagawa.springViolet1)),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(children: [
          _SwitchRow(
            title: 'MÚSICA 8-BIT',
            subtitle: 'Toca enquanto o app está aberto.',
            value: s.music,
            onChanged: (v) {
              Sfx.click.play();
              ctrl.apply((g) => g.music = v);
            },
          ),
          _SwitchRow(
            title: 'EFEITOS SONOROS',
            value: s.sound,
            onChanged: (v) {
              ctrl.apply((g) => g.sound = v);
              if (v) Sfx.click.play();
            },
          ),
          _SwitchRow(
            title: 'NOTIFICAÇÕES',
            subtitle: 'Avisa no celular quando cada missão começa.',
            value: s.alerts,
            onChanged: (v) {
              Sfx.click.play();
              ctrl.apply((g) => g.alerts = v);
              if (v) ref.read(missionAlertsProvider).requestPermission();
            },
          ),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('PERSONAGEM', style: PixelText.display(10)),
          const SizedBox(height: 12),
          TextField(controller: _name, maxLength: 24, style: PixelText.body(16), decoration: pixelInput('Nome')),
          Align(
            alignment: Alignment.centerLeft,
            child: PixelButton(
              label: 'Salvar nome',
              sound: false,
              onPressed: () {
                final n = _name.text.trim();
                if (n.isEmpty) return;
                ctrl.apply((g) => g.name = n);
                Sfx.save.play();
                showToast(context, 'Nome salvo');
              },
            ),
          ),
          const SizedBox(height: 16),
          if (!_confirmReset)
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(
                label: 'Recomeçar a jornada',
                color: Kanagawa.sumiInk5,
                textColor: Kanagawa.fujiWhite,
                onPressed: () => setState(() => _confirmReset = true),
              ),
            )
          else
            ConfirmBar(
              text: 'Apagar agenda e progresso e voltar a Belém?',
              yesLabel: 'Recomeçar',
              onNo: () => setState(() => _confirmReset = false),
              onYes: () async {
                setState(() => _confirmReset = false);
                Sfx.delete.play();
                await ctrl.reset();
              },
            ),
        ]),
      ),
    ]);
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged, this.subtitle});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: PixelText.display(8)),
              if (subtitle != null) Text(subtitle!, style: PixelText.body(13, color: Kanagawa.springViolet1)),
            ]),
          ),
          Switch(value: value, activeThumbColor: Kanagawa.carpYellow, onChanged: onChanged),
        ]),
      );
}
