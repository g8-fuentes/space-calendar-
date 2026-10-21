import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/game_rules.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

final _shopTabProvider = StateProvider<String>((ref) => 'skin');

/// Loja: skins, aparências, companheiros, poderes mágicos, poderes,
/// melhorias da nave e recompensas da vida real.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_shopTabProvider);
    final coins = ref.watch(statsProvider.select((t) => t.coins));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('LOJA', style: PixelText.display(11)),
            CoinPrice(coins),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (k, n) in shopSections)
              Semantics(
                button: true,
                selected: tab == k,
                child: InkWell(
                  onTap: () {
                    Sfx.tab.play();
                    ref.read(_shopTabProvider.notifier).state = k;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                    color: tab == k ? Kanagawa.carpYellow : Kanagawa.sumiInk0,
                    child: Text(n.toUpperCase(), style: PixelText.display(7, color: tab == k ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          switch (tab) {
            'ship' => const _Upgrades(),
            'real' => const _Rewards(),
            _ => _Items(section: tab),
          },
        ]),
      ),
    ]);
  }
}

class _Items extends ConsumerWidget {
  const _Items({required this.section});
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = shopItems.where((i) => i.category == section).toList();
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 520 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 270),
        itemBuilder: (_, i) => _ItemCard(item: items[i]),
      );
    });
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final coins = ref.watch(statsProvider.select((t) => t.coins));
    final owned = !item.isPower && s.owned.contains(item.id);
    final equipped = owned && s.equipped[item.slot] == item.id;
    final ctrl = ref.read(gameControllerProvider.notifier);
    Widget action;
    if (item.isPower) {
      action = PixelButton(
        label: 'Comprar',
        dense: true,
        sound: false,
        onPressed: coins < item.price
            ? null
            : () {
                ctrl.apply((g) => GameRules.buyPower(g, item, coins, ctrl.now), burst: item.id == 'pw_hyper' ? 150 : 0);
                Sfx.power.play();
                showToast(context, 'Poder ativado: ${item.name}');
              },
      );
    } else if (owned) {
      action = PixelButton(
        label: equipped ? 'Equipado' : 'Equipar',
        dense: true,
        sound: false,
        color: equipped ? Kanagawa.springBlue : Kanagawa.sumiInk0,
        textColor: equipped ? Kanagawa.sumiInk0 : Kanagawa.fujiWhite,
        onPressed: () {
          final on = ctrl.apply((g) => GameRules.toggleEquip(g, item));
          Sfx.equip.play();
          showToast(context, '${on ? 'Equipado' : 'Removido'}: ${item.name}');
        },
      );
    } else {
      action = PixelButton(
        label: 'Comprar',
        dense: true,
        sound: false,
        onPressed: coins < item.price
            ? null
            : () {
                ctrl.apply((g) => GameRules.buyCosmetic(g, item, coins, ctrl.now), burst: 0);
                Sfx.buy.play();
                showToast(context, 'Comprado e equipado: ${item.name}');
              },
      );
    }
    return Container(
      color: Kanagawa.sumiInk5,
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: SizedBox(
            width: 120,
            height: 96,
            child: CustomPaint(painter: _ThumbPainter(item)),
          ),
        ),
        const SizedBox(height: 8),
        Text(item.name.toUpperCase(), style: PixelText.display(8).copyWith(height: 1.6), maxLines: 2),
        const SizedBox(height: 4),
        Expanded(child: Text(item.description, style: PixelText.body(13, color: Kanagawa.springViolet1))),
        Row(children: [
          if (owned)
            Text('SEU', style: PixelText.display(8, color: Kanagawa.carpYellow))
          else
            CoinPrice(item.price),
          const Spacer(),
        ]),
        const SizedBox(height: 6),
        action,
      ]),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.item);
  final ShopItem item;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 60, size.height / 48);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 60, 48));
    paintShopThumb(canvas, item, 40);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.item.id != item.id;
}

class _Upgrades extends ConsumerWidget {
  const _Upgrades();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final coins = ref.watch(statsProvider.select((t) => t.coins));
    final ctrl = ref.read(gameControllerProvider.notifier);
    return Column(children: [
      for (final u in upgrades) ...[
        Container(
          color: Kanagawa.sumiInk5,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${u.name} · nível ${s.upgradeLevel(u.id)}'.toUpperCase(), style: PixelText.display(8).copyWith(height: 1.6)),
            const SizedBox(height: 6),
            Text('${u.description}. Sem limite de níveis.', style: PixelText.body(14, color: Kanagawa.springViolet1)),
            const SizedBox(height: 8),
            Row(children: [
              CoinPrice(u.cost(s.upgradeLevel(u.id))),
              const Spacer(),
              PixelButton(
                label: 'Melhorar',
                dense: true,
                sound: false,
                onPressed: coins < u.cost(s.upgradeLevel(u.id))
                    ? null
                    : () {
                        ctrl.apply((g) => GameRules.buyUpgrade(g, u, coins, ctrl.now));
                        Sfx.buy.play();
                        showToast(context, '${u.name} agora no nível ${ref.read(gameControllerProvider).upgradeLevel(u.id)}');
                      },
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }
}

class _Rewards extends ConsumerStatefulWidget {
  const _Rewards();

  @override
  ConsumerState<_Rewards> createState() => _RewardsState();
}

class _RewardsState extends ConsumerState<_Rewards> {
  final _name = TextEditingController();
  final _price = TextEditingController(text: '150');

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameControllerProvider);
    final coins = ref.watch(statsProvider.select((t) => t.coins));
    final ctrl = ref.read(gameControllerProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Recompensas da vida real que você mesmo define. Compre quando tiver moedas e aproveite de verdade.',
          style: PixelText.body(14, color: Kanagawa.springViolet1)),
      const SizedBox(height: 10),
      for (final Reward r in s.rewards) ...[
        Container(
          color: Kanagawa.sumiInk5,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name.toUpperCase(), style: PixelText.display(8).copyWith(height: 1.6)),
            const SizedBox(height: 8),
            Row(children: [
              CoinPrice(r.price),
              const Spacer(),
              PixelButton(
                label: 'Remover',
                dense: true,
                sound: false,
                color: Kanagawa.sumiInk0,
                textColor: Kanagawa.fujiWhite,
                onPressed: () {
                  ctrl.apply((g) => GameRules.removeReward(g, r.id));
                  Sfx.delete.play();
                },
              ),
              const SizedBox(width: 6),
              PixelButton(
                label: 'Resgatar',
                dense: true,
                sound: false,
                onPressed: coins < r.price
                    ? null
                    : () {
                        ctrl.apply((g) => GameRules.redeemReward(g, r, coins, ctrl.now));
                        ctrl.notify([Notice('RECOMPENSA RESGATADA!', '${r.name}. Você mereceu, aproveite.', sound: 'chest')]);
                      },
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          flex: 2,
          child: TextField(
              controller: _name, maxLength: 60, style: PixelText.body(16), decoration: pixelInput('Nova recompensa', hint: 'Ex.: Pizza no sábado')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(controller: _price, keyboardType: TextInputType.number, maxLength: 5, style: PixelText.body(16), decoration: pixelInput('Preço')),
        ),
      ]),
      Align(
        alignment: Alignment.centerLeft,
        child: PixelButton(
          label: 'Adicionar',
          sound: false,
          onPressed: () {
            final n = _name.text.trim(), p = int.tryParse(_price.text.trim()) ?? 0;
            if (n.isEmpty || p <= 0) {
              Sfx.error.play();
              return;
            }
            ctrl.apply((g) => GameRules.addReward(g, n, p));
            Sfx.save.play();
            _name.clear();
            showToast(context, 'Recompensa adicionada');
          },
        ),
      ),
    ]);
  }
}
