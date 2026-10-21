import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../domain/catalog/catalog.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import '../widgets/event_presenter.dart';
import '../widgets/pixel_canvas.dart';
import '../widgets/pixel_widgets.dart';

/// Pede confirmação antes de gastar moedas.
Future<bool> _confirm(BuildContext context, String what, int price) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('CONFIRMAR', style: PixelText.display(12, color: Kanagawa.carpYellow)),
      content: Text('Gastar $price moedas em "$what"?', style: PixelText.body(16)),
      actions: [
        PixelButton(
          label: 'Cancelar',
          color: Kanagawa.sumiInk5,
          textColor: Kanagawa.fujiWhite,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        PixelButton(label: 'Confirmar', onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  return ok ?? false;
}

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final stats = ref.watch(statsProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Expanded(child: SectionTitle('Loja', color: Kanagawa.fujiWhite)),
          CoinPrice(stats.coins),
        ]),
        const SizedBox(height: 16),
        const SectionTitle('Melhorias da nave · sem limite de nível'),
        const SizedBox(height: 8),
        for (final u in upgradeCatalog)
          _ShopCard(
            title: '${u.name} · NV ${state.upgradeLevel(u.id)}',
            subtitle: '${u.description}. Bônus atual: +${u.percentPerLevel * state.upgradeLevel(u.id)}%.',
            price: u.costFor(state.upgradeLevel(u.id)),
            action: 'Melhorar',
            enabled: stats.coins >= u.costFor(state.upgradeLevel(u.id)),
            onTap: () async {
              if (await _confirm(context, u.name, u.costFor(state.upgradeLevel(u.id)))) {
                ctrl.buyUpgrade(u);
                if (context.mounted) showGameToast(context, '${u.name} melhorado');
              }
            },
          ),
        const SizedBox(height: 12),
        const SectionTitle('Visual do astronauta'),
        const SizedBox(height: 8),
        for (final c in cosmeticCatalog)
          _ShopCard(
            leading: PixelCanvas(
              logicalSize: const Size(56, 72),
              size: const Size(48, 62),
              paint: (canvas) {
                if (c.slot == CosmeticSlot.pet || c.slot == CosmeticSlot.satellite) {
                  paintPet(canvas, c.id, const Offset(22, 32));
                } else {
                  paintGrid(canvas, astronautGrid(rank: 0, mk: 1, equipped: {c.slot.name: c.id}), const Offset(2, 4), 2);
                }
              },
            ),
            title: c.name,
            subtitle: c.description,
            price: state.owned.contains(c.id) ? null : c.price,
            status: state.owned.contains(c.id) ? (state.equipped[c.slot.name] == c.id ? 'EQUIPADO' : 'SEU') : null,
            action: state.owned.contains(c.id)
                ? (state.equipped[c.slot.name] == c.id ? 'Tirar' : 'Equipar')
                : 'Comprar',
            secondary: state.owned.contains(c.id),
            enabled: state.owned.contains(c.id) || stats.coins >= c.price,
            onTap: () async {
              if (state.owned.contains(c.id)) {
                ctrl.toggleEquip(c);
              } else if (await _confirm(context, c.name, c.price)) {
                ctrl.buyCosmetic(c);
                if (context.mounted) showGameToast(context, 'Comprou ${c.name}');
              }
            },
          ),
        const SizedBox(height: 12),
        const SectionTitle('Recompensas da vida real'),
        const SizedBox(height: 8),
        for (final r in state.rewards)
          _ShopCard(
            title: r.name,
            subtitle: () {
              final n = state.purchases.where((p) => p.id == r.id).length;
              return n == 0 ? 'Ainda não resgatado' : 'Resgatado ${n}x';
            }(),
            price: r.price,
            action: 'Resgatar',
            enabled: stats.coins >= r.price,
            onTap: () async {
              if (await _confirm(context, r.name, r.price)) {
                ctrl.redeemReward(r);
                if (context.mounted) showGameToast(context, 'Recompensa liberada: ${r.name}');
              }
            },
          ),
        const SizedBox(height: 8),
        const _NewRewardForm(),
      ]),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.enabled,
    required this.onTap,
    this.price,
    this.status,
    this.leading,
    this.secondary = false,
  });

  final String title;
  final String subtitle;
  final String action;
  final bool enabled;
  final VoidCallback onTap;
  final int? price;
  final String? status;
  final Widget? leading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelPanel(
        child: Row(children: [
          if (leading != null) ...[
            Container(color: Kanagawa.sumiInk0, padding: const EdgeInsets.all(4), child: leading),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.toUpperCase(), style: PixelText.display(8)),
              const SizedBox(height: 4),
              Text(subtitle, style: PixelText.body(14, color: Kanagawa.springViolet1)),
              const SizedBox(height: 6),
              if (price != null) CoinPrice(price!),
              if (status != null) Text(status!, style: PixelText.display(8, color: Kanagawa.carpYellow)),
            ]),
          ),
          const SizedBox(width: 8),
          PixelButton(
            label: action,
            color: secondary ? Kanagawa.sumiInk5 : Kanagawa.carpYellow,
            textColor: secondary ? Kanagawa.fujiWhite : Kanagawa.sumiInk0,
            onPressed: enabled ? onTap : null,
          ),
        ]),
      ),
    );
  }
}

class _NewRewardForm extends ConsumerStatefulWidget {
  const _NewRewardForm();

  @override
  ConsumerState<_NewRewardForm> createState() => _NewRewardFormState();
}

class _NewRewardFormState extends ConsumerState<_NewRewardForm> {
  final _name = TextEditingController();
  final _price = TextEditingController(text: '100');

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showGameToast(context, 'Escreva o nome da recompensa');
      return;
    }
    ref.read(gameControllerProvider.notifier).addReward(name, int.tryParse(_price.text) ?? 100);
    _name.clear();
    showGameToast(context, 'Recompensa adicionada');
  }

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NOVA RECOMPENSA', style: PixelText.display(8, color: Kanagawa.springViolet1)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          maxLength: 40,
          style: PixelText.body(16),
          decoration: const InputDecoration(hintText: 'Ex.: açaí depois do futsal', counterText: ''),
        ),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              style: PixelText.body(16),
              decoration: const InputDecoration(labelText: 'Preço'),
            ),
          ),
          const SizedBox(width: 10),
          PixelButton(label: 'Adicionar', onPressed: _add),
        ]),
      ]),
    );
  }
}
