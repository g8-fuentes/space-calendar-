import 'package:flutter/material.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';
import '../../domain/services/game_rules.dart';
import 'pixel_widgets.dart';

/// Mostra um aviso para os acontecimentos importantes (nível, rank,
/// destino, curso, baú). Eventos menores viram uma mensagem curta.
Future<void> presentEvents(BuildContext context, List<GameEvent> events) async {
  if (events.isEmpty || !context.mounted) return;
  String? title;
  final lines = <String>[];
  for (final e in events) {
    switch (e) {
      case ChestOpened(:final loot):
        title ??= 'BAÚ ${tierByKey(loot.tier).name.toUpperCase()}';
        final item = loot.item == null ? null : cosmeticById(loot.item!)?.name;
        lines.add('+${loot.coins} moedas e +${loot.xp} XP'
            '${loot.bossDefeated ? ' (inclui bônus do duelo)' : ''}'
            '${item == null ? '.' : '. Item novo: $item.'}');
      case ArrivedAt(:final destinationIndex):
        final d = destinationAt(destinationIndex);
        title ??= 'CHEGOU EM ${d.name.toUpperCase()}!';
        lines.add('${d.fact} Próximo destino: ${destinationAt(destinationIndex + 1).name}.');
      case CourseCompleted(:final course):
        title ??= 'CURSO CONCLUÍDO!';
        lines.add('${course.name} derrotado. +$courseXp XP e +$courseCoins moedas.');
      case RankUp(:final rank):
        title ??= 'NOVO RANK!';
        lines.add('Guilherme agora é ${rank.name}. A energia ao redor dele ficou mais forte.');
      case LevelUp(:final level):
        title ??= 'LEVEL UP!';
        lines.add('Guilherme chegou ao nível $level.');
      case NewSuit(:final mk):
        lines.add('Traje Mk $mk equipado.');
      case ModeUnlocked(:final mode):
        lines.add('Novo modo do traje liberado: ${mode.name}.');
    }
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? 'MISSÃO', style: PixelText.display(13, color: Kanagawa.carpYellow)),
      content: Text(lines.join('\n\n'), style: PixelText.body(16)),
      actions: [PixelButton(label: 'Continuar', onPressed: () => Navigator.of(ctx).pop())],
    ),
  );
}

void showGameToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 2200)));
}
