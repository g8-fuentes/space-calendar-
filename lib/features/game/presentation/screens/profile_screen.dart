import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/time/week_utils.dart';
import '../../domain/catalog/achievements.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/schedule.dart';
import '../../domain/entities/quest.dart';
import '../../domain/services/game_stats.dart';
import '../controllers/game_providers.dart';
import '../widgets/event_presenter.dart';
import '../widgets/pixel_widgets.dart';

/// Ranks, modos do traje, atributos, medalhas, conquistas e histórico.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final state = ref.watch(gameControllerProvider);
    final stats = ref.watch(statsProvider);
    final ri = stats.rankIndex;
    final start = ri < 2 ? 0 : ri - 2;
    final nextRank = rankAt(ri + 1);
    final week = state.week(weekKeyOf(now));
    final history = state.weeks.keys
        .where((k) => state.weeks[k]!.done.isNotEmpty || state.weeks[k]!.chest != null)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('PERFIL')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionTitle('Rank'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.6,
          children: [
            for (var i = start; i < start + 6; i++)
              _RankTile(rank: rankAt(i), reached: i <= ri, current: i == ri),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Próximo rank: ${nextRank.name} no nível ${nextRank.level} (faltam ${nextRank.level - stats.lv}). '
          'Traje atual: Mk ${stats.suitMk}; o Mk ${stats.suitMk + 1} chega no nível ${suitMkStartLevel(stats.suitMk + 1)}.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Modos do traje'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in suitModes)
            _ModeChip(
              mode: m,
              unlocked: stats.modeUnlocked(m),
              active: state.suitMode == m.id,
              onTap: () {
                ref.read(gameControllerProvider.notifier).setSuitMode(m.id);
                if (m.id > 0) showGameToast(context, 'Modo ativado: ${m.name}');
              },
            ),
        ]),
        const SizedBox(height: 18),
        const SectionTitle('Atributos da semana'),
        const SizedBox(height: 8),
        for (final c in QuestCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: () {
              final qs = allQuests.where((q) => q.category == c).toList();
              final done = qs.where((q) => week.done.containsKey(q.id)).length;
              return Row(children: [
                SizedBox(width: 96, child: Text(c.attribute, style: PixelText.body(15))),
                Expanded(child: PixelBar(value: done / qs.length, color: Kanagawa.category(c))),
                SizedBox(
                  width: 52,
                  child: Text('$done/${qs.length}',
                      textAlign: TextAlign.right, style: PixelText.body(13, color: Kanagawa.springViolet1)),
                ),
              ]);
            }(),
          ),
        const SizedBox(height: 18),
        const SectionTitle('Medalhas sem fim'),
        const SizedBox(height: 4),
        Text('Cada medalha sobe de nível sempre que você dobra a meta anterior.',
            style: PixelText.body(13, color: Kanagawa.springViolet1)),
        const SizedBox(height: 8),
        for (final m in medals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: () {
              final v = m.value(stats, state);
              final t = medalTierFor(m.base, v);
              return PixelPanel(
                accent: Color(m.color),
                child: Row(children: [
                  _Badge(glyph: '${t.tier}', color: Color(m.color)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name.toUpperCase(), style: PixelText.display(8)),
                      const SizedBox(height: 6),
                      PixelBar(value: t.progress(v), color: Color(m.color), height: 8),
                      const SizedBox(height: 4),
                      Text('$v de ${t.goal} para o nível ${t.tier + 1}', style: PixelText.body(13)),
                    ]),
                  ),
                ]),
              );
            }(),
          ),
        const SizedBox(height: 10),
        SectionTitle('Conquistas · ${achievements.where((a) => a.check(stats, state, now)).length}/${achievements.length}'),
        const SizedBox(height: 8),
        for (final a in achievements)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Opacity(
              opacity: a.check(stats, state, now) ? 1 : .45,
              child: PixelPanel(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  _Badge(glyph: a.glyph, color: Color(a.color)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.name.toUpperCase(), style: PixelText.display(8)),
                      Text(a.description, style: PixelText.body(13, color: Kanagawa.springViolet1)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 14),
        const SectionTitle('Histórico'),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Text('Nenhuma semana jogada ainda. Marque sua primeira missão de hoje para começar.',
              style: PixelText.body(14, color: Kanagawa.springViolet1))
        else
          for (final k in history)
            () {
              final ws = weekStatsOf(state, k);
              final tier = tierFor(ws.ratio);
              final beat = ws.xp >= bossForWeek(k, weekMaxXp).hp;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${k.substring(8)}/${k.substring(5, 7)}/${k.substring(0, 4)} · ${ws.done}/${allQuests.length} · '
                  '${(ws.ratio * 100).round()}% · ${ws.xp} XP · duelo ${beat ? 'vencido' : '—'} · baú ${tier?.name ?? '—'}',
                  style: PixelText.body(14),
                ),
              );
            }(),
        const SizedBox(height: 24),
        const _ResetButton(),
      ]),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.reached, required this.current});
  final Rank rank;
  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = Color(rank.color);
    final fg = reached ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: reached ? c : Kanagawa.sumiInk5,
        border: Border(
          bottom: BorderSide(color: c, width: 4),
          top: BorderSide(color: current ? Kanagawa.fujiWhite : Kanagawa.sumiInk0, width: 3),
          left: BorderSide(color: current ? Kanagawa.fujiWhite : Kanagawa.sumiInk0, width: 3),
          right: BorderSide(color: current ? Kanagawa.fujiWhite : Kanagawa.sumiInk0, width: 3),
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(rank.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: PixelText.body(12, color: fg)),
        Text('LV ${rank.level}', style: PixelText.body(11, color: fg)),
      ]),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode, required this.unlocked, required this.active, required this.onTap});
  final SuitMode mode;
  final bool unlocked;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Color(mode.color);
    return Semantics(
      button: true,
      selected: active,
      enabled: unlocked,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        child: Opacity(
          opacity: unlocked ? 1 : .55,
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? c : Kanagawa.sumiInk5,
              border: Border.all(color: Kanagawa.sumiInk0, width: 3),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mode.name.toUpperCase(),
                  style: PixelText.display(7, color: active ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
              const SizedBox(height: 4),
              Text(unlocked ? 'liberado' : mode.requirement,
                  style: PixelText.body(12, color: active ? Kanagawa.sumiInk0 : Kanagawa.springViolet1)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.glyph, required this.color});
  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, border: Border.all(color: Kanagawa.sumiInk0, width: 3)),
        child: Text(glyph, style: PixelText.display(9, color: Kanagawa.sumiInk0)),
      );
}

class _ResetButton extends ConsumerWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: PixelButton(
        label: 'Zerar jogo',
        color: Kanagawa.autumnRed,
        textColor: Kanagawa.fujiWhite,
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('ZERAR JOGO?', style: PixelText.display(12, color: Kanagawa.waveRed)),
              content: Text('Todo o progresso será apagado deste aparelho. Isso não pode ser desfeito.',
                  style: PixelText.body(16)),
              actions: [
                PixelButton(
                  label: 'Cancelar',
                  color: Kanagawa.sumiInk5,
                  textColor: Kanagawa.fujiWhite,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                PixelButton(
                  label: 'Zerar',
                  color: Kanagawa.autumnRed,
                  textColor: Kanagawa.fujiWhite,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          );
          if (ok ?? false) {
            await ref.read(gameControllerProvider.notifier).reset();
            if (context.mounted) showGameToast(context, 'Jogo zerado');
          }
        },
      ),
    );
  }
}
