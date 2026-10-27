import 'package:flutter/material.dart';

import 'theme/kanagawa.dart';

/// Tela mostrada quando o app não consegue abrir, com o erro visível
/// para que dê para saber o que corrigir.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Kanagawa.sumiInk3,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StartupErrorBox(message: '$error\n\n$stack'),
          ),
        ),
      ),
    );
  }
}

class StartupErrorBox extends StatelessWidget {
  const StartupErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Kanagawa.sumiInk0,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Ops, algo deu errado no Divine Routine:\n\n$message',
        style: const TextStyle(color: Kanagawa.fujiWhite, fontSize: 12, fontFamily: 'monospace'),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
