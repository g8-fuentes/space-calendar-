import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../controllers/sync_controller.dart';
import 'pixel_widgets.dart';
import 'ui.dart';

/// Conta na nuvem: entrar, criar conta, sincronizar e sair. Com a conta,
/// o progresso fica igual no celular e no computador.
class SyncPanel extends ConsumerStatefulWidget {
  const SyncPanel({super.key, this.intro = false});

  /// Na tela inicial: texto voltado para quem já usa em outro aparelho.
  final bool intro;

  @override
  ConsumerState<SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends ConsumerState<SyncPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _message;
  bool _messageIsError = true;
  bool _open = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool create}) async {
    setState(() => _message = null);
    final msg = await ref.read(syncProvider.notifier).signIn(_email.text, _password.text, create: create);
    if (!mounted) return;
    final ok = ref.read(syncProvider).signedIn;
    if (ok) {
      Sfx.save.play();
      _password.clear();
      showToast(context, 'Conta conectada: progresso sincronizado');
    } else {
      Sfx.error.play();
    }
    setState(() {
      _message = msg;
      _messageIsError = !ok && !(msg?.startsWith('Conta criada') ?? false);
    });
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'agora mesmo';
    if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
    return 'às ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);
    if (!sync.available) {
      if (widget.intro) return const SizedBox.shrink();
      return PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('NUVEM', style: PixelText.display(10)),
          const SizedBox(height: 6),
          Text(
              'A sincronização entre aparelhos ainda não foi configurada nesta versão. '
              'O progresso fica salvo só neste aparelho.',
              style: PixelText.body(14, color: Kanagawa.springViolet1)),
        ]),
      );
    }

    final children = <Widget>[
      Text(widget.intro ? 'JÁ USA EM OUTRO APARELHO?' : 'NUVEM', style: PixelText.display(10)),
      const SizedBox(height: 6),
    ];

    if (sync.signedIn) {
      children.addAll([
        Text('Conectado como ${sync.email}.', style: PixelText.body(15)),
        const SizedBox(height: 4),
        Text(
          sync.busy
              ? 'Sincronizando…'
              : sync.lastSync == null
                  ? 'Seu progresso fica igual no celular e no computador.'
                  : 'Sincronizado ${_ago(sync.lastSync!)}. Seu progresso fica igual no celular e no computador.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        ErrorText(sync.error),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 8, children: [
          PixelButton(
            label: 'Sincronizar agora',
            dense: true,
            onPressed: sync.busy ? null : () => ref.read(syncProvider.notifier).syncNow(),
          ),
          PixelButton(
            label: 'Sair da conta',
            dense: true,
            color: Kanagawa.sumiInk5,
            textColor: Kanagawa.fujiWhite,
            onPressed: () => ref.read(syncProvider.notifier).signOut(),
          ),
        ]),
      ]);
    } else if (!_open) {
      children.addAll([
        Text(
          widget.intro
              ? 'Entre com sua conta para trazer missões, níveis e a chama de Disciplina.'
              : 'Entre com uma conta para usar o mesmo progresso no celular e no computador. '
                  'O que já está neste aparelho vai junto para a nuvem.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        ErrorText(sync.error),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PixelButton(
            label: widget.intro ? 'Entrar na minha conta' : 'Entrar ou criar conta',
            color: widget.intro ? Kanagawa.sumiInk5 : null,
            textColor: widget.intro ? Kanagawa.fujiWhite : null,
            onPressed: () => setState(() => _open = true),
          ),
        ),
      ]);
    } else {
      children.addAll([
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: PixelText.body(16),
          decoration: pixelInput('E-mail'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          style: PixelText.body(16),
          decoration: pixelInput('Senha', hint: 'pelo menos 6 caracteres'),
          onSubmitted: (_) => _submit(create: false),
        ),
        const SizedBox(height: 10),
        if (sync.busy)
          Text('Conectando…', style: PixelText.body(14, color: Kanagawa.springViolet1))
        else
          Wrap(spacing: 10, runSpacing: 8, children: [
            PixelButton(label: 'Entrar', dense: true, sound: false, onPressed: () => _submit(create: false)),
            PixelButton(
              label: 'Criar conta',
              dense: true,
              sound: false,
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              onPressed: () => _submit(create: true),
            ),
          ]),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_message!,
                style: PixelText.body(15, color: _messageIsError ? Kanagawa.sakuraPink : Kanagawa.springGreen)),
          ),
      ]);
    }

    return PixelPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }
}
