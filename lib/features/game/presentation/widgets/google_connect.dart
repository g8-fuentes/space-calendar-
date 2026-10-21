import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/services/calendar_import.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import 'pixel_widgets.dart';
import 'ui.dart';

/// Folha para colar o endereço secreto iCal do Google Agenda.
/// Com [astronautName], também conclui a tela inicial.
Future<void> openGoogleConnect(BuildContext context, {String? astronautName}) =>
    openSheet<void>(context, (_) => _GoogleConnectSheet(astronautName: astronautName));

/// Sincroniza pelo botão: conecta primeiro se ainda não houver agenda.
Future<void> syncOrConnect(BuildContext context, WidgetRef ref) async {
  if (ref.read(gameControllerProvider).calendarUrl == null) return openGoogleConnect(context);
  final err = await syncGoogleCalendar(context, ref);
  if (err != null && context.mounted) showToast(context, err);
}

class _GoogleConnectSheet extends ConsumerStatefulWidget {
  const _GoogleConnectSheet({this.astronautName});
  final String? astronautName;

  @override
  ConsumerState<_GoogleConnectSheet> createState() => _GoogleConnectSheetState();
}

class _GoogleConnectSheetState extends ConsumerState<_GoogleConnectSheet> {
  late final _url = TextEditingController(text: ref.read(gameControllerProvider).calendarUrl ?? '');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => _url.text = data!.text!.trim());
  }

  Future<void> _connect() async {
    final url = normalizeCalendarUrl(_url.text);
    if (url == null) {
      Sfx.error.play();
      setState(() => _error = 'Cole o endereço completo, começando com https://');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await syncGoogleCalendar(context, ref, url: url, astronautName: widget.astronautName);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'No navegador (no celular, ative "Versão para computador"), abra calendar.google.com.',
      'Em "Minhas agendas", toque nos três pontinhos da sua agenda e escolha "Configurações e compartilhamento".',
      'Desça até "Integrar agenda" e copie o "Endereço secreto no formato iCal".',
      'Cole aqui embaixo e toque em Conectar.',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text('CONECTAR GOOGLE AGENDA', style: PixelText.display(11, color: Kanagawa.carpYellow)),
      const SizedBox(height: 12),
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 24, child: Text('${i + 1}.', style: PixelText.display(9, color: Kanagawa.carpYellow))),
            Expanded(child: Text(steps[i], style: PixelText.body(15))),
          ]),
        ),
      const SizedBox(height: 6),
      TextField(
        controller: _url,
        style: PixelText.body(14),
        keyboardType: TextInputType.url,
        autocorrect: false,
        maxLines: 2,
        minLines: 1,
        decoration: pixelInput('Endereço secreto iCal', hint: 'https://calendar.google.com/calendar/ical/.../basic.ics'),
        onSubmitted: (_) => _connect(),
      ),
      ErrorText(_error),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        PixelButton(label: _busy ? 'Conectando...' : 'Conectar', sound: false, onPressed: _busy ? null : _connect),
        PixelButton(label: 'Colar', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: _busy ? null : _paste),
      ]),
      const SizedBox(height: 14),
      Container(
        color: Kanagawa.sumiInk0,
        padding: const EdgeInsets.all(12),
        child: Text(
          'O app só lê a agenda: nada é alterado no Google. O endereço fica salvo apenas neste celular; '
          'não compartilhe com ninguém. Eventos que se repetem viram missões semanais, e eventos avulsos '
          'entram só na semana em que acontecem.',
          style: PixelText.body(13, color: Kanagawa.springViolet1),
        ),
      ),
    ]);
  }
}
