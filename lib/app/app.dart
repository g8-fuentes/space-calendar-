import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/kanagawa.dart';

class RotinaQuestApp extends StatelessWidget {
  const RotinaQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rotina Quest',
      debugShowCheckedModeBanner: false,
      theme: buildKanagawaTheme(),
      routerConfig: appRouter,
    );
  }
}
