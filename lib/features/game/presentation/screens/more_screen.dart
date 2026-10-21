import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';
import '../../../../core/text/text_utils.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/destinations.dart';
import '../../domain/services/game_stats.dart';
import '../art/pixel_art.dart';
import '../controllers/game_providers.dart';
import '../controllers/import_flow.dart';
import '../widgets/google_connect.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/ui.dart';

/// Mapa da galáxia, conquistas (com bestiário) e ajustes.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Material(
          color: Kanagawa.sumiInk0,
          child: TabBar(
            onTap: (_) => Sfx.tab.play(),
            indicatorColor: Kanagawa.carpYellow,
            labelColor: Kanagawa.carpYellow,
            unselectedLabelColor: Kanagawa.springViolet1,
            labelStyle: PixelText.display(8),
            tabs: const [Tab(text: 'MAPA'), Tab(text: 'CONQUISTAS'), Tab(text: 'AJUSTES')],
          ),
        ),
        const Expanded(child: TabBarView(children: [_MapTab(), _AchievementsTab(), _SettingsTab()])),
      ]),
    );
  }
}

// ---------- Mapa ----------

class _MapTab extends ConsumerWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(statsProvider);
    final di = t.destinationIndex;
    final last = math.max(di + 3, 10);
    final here = t.destination, next = t.nextDestination;
    final span = next.xpRequired - here.xpRequired;
    final ratio = span <= 0 ? 1.0 : ((t.xp - here.xpRequired) / span).clamp(0.0, 1.0);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('MAPA DA GALÁXIA', style: PixelText.display(11)),
          const SizedBox(height: 6),
          Text('Você está em ${here.name}. Próximo destino: ${next.name}.',
              style: PixelText.body(15, color: Kanagawa.springViolet1)),
          const SizedBox(height: 8),
          PixelBar(value: ratio, color: Kanagawa.springBlue),
          const SizedBox(height: 4),
          Text('${t.xp} / ${next.xpRequired} XP', style: PixelText.body(14, color: Kanagawa.springViolet1)),
        ]),
      ),
      const SizedBox(height: 14),
      for (var i = 0; i <= last; i++) ...[
        _DestinationTile(d: destinationAt(i), reached: i <= di, current: i == di),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.d, required this.reached, required this.current});
  final Destination d;
  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: current ? Kanagawa.waveBlue1 : Kanagawa.sumiInk4,
        border: Border.all(color: current ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
      ),
      child: Row(children: [
        Opacity(
          opacity: reached ? 1 : .35,
          child: SizedBox(width: 56, height: 56, child: CustomPaint(painter: _BodyPainter(d))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reached ? d.name.toUpperCase() : '???', style: PixelText.display(9, color: reached ? Kanagawa.fujiWhite : Kanagawa.springViolet1)),
            const SizedBox(height: 4),
            Text(reached ? d.fact : 'Ainda não visitado.', style: PixelText.body(14, color: Kanagawa.springViolet1)),
            Text('${d.xpRequired} XP${current ? ' · você está aqui' : ''}',
                style: PixelText.body(13, color: current ? Kanagawa.carpYellow : Kanagawa.sumiInk6)),
          ]),
        ),
      ]),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.d);
  final Destination d;

  @override
  void paint(Canvas canvas, Size size) =>
      paintBody(canvas, d, size.center(Offset.zero), size.shortestSide * .32, 0);

  @override
  bool shouldRepaint(covariant _BodyPainter old) => old.d.index != d.index;
}

// ---------- Conquistas ----------

class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final t = ref.watch(statsProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final list = achievementsOf(s, t, now);
    final got = list.where((a) => a.unlocked).length;
    final from = math.max(1, t.lv - 11);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Text('CONQUISTAS · $got/${list.length}', style: PixelText.display(10)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.25,
        children: [for (final a in list) _AchievementCard(a)],
      ),
      const SizedBox(height: 20),
      Text('BESTIÁRIO', style: PixelText.display(10)),
      const SizedBox(height: 4),
      Text('Um inimigo novo a cada nível e um chefe a cada 10.', style: PixelText.body(14, color: Kanagawa.springViolet1)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .62,
        children: [
          for (var lv = t.lv; lv >= from; lv--) _FoeCard(enemyFor(lv), current: lv == t.lv),
        ],
      ),
    ]);
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(this.a);
  final Achievement a;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: a.unlocked ? Kanagawa.waveBlue1 : Kanagawa.sumiInk4,
          border: Border.all(color: a.unlocked ? Kanagawa.carpYellow : Kanagawa.sumiInk0, width: 3),
        ),
        child: Opacity(
          opacity: a.unlocked ? 1 : .5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.icon, style: PixelText.display(12, color: a.unlocked ? Kanagawa.carpYellow : Kanagawa.springViolet1)),
            const SizedBox(height: 6),
            Text(a.name, style: PixelText.display(7), maxLines: 2),
            const SizedBox(height: 4),
            Expanded(child: Text(a.description, style: PixelText.body(13, color: Kanagawa.springViolet1))),
          ]),
        ),
      );
}

class _FoeCard extends StatelessWidget {
  const _FoeCard(this.e, {required this.current});
  final Enemy e;
  final bool current;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Kanagawa.sumiInk0,
          border: Border.all(color: e.boss ? Kanagawa.autumnRed : (current ? Kanagawa.carpYellow : Kanagawa.sumiInk5), width: 3),
        ),
        child: Column(children: [
          AspectRatio(aspectRatio: 1, child: CustomPaint(painter: EnemyPainter(e))),
          const SizedBox(height: 4),
          Text('NV ${e.level}${e.boss ? ' · CHEFE' : ''}', style: PixelText.display(6, color: e.boss ? Kanagawa.waveRed : Kanagawa.carpYellow)),
          const SizedBox(height: 2),
          Expanded(
            child: Text(e.name, textAlign: TextAlign.center, style: PixelText.body(12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Text(current ? 'Encarando você agora.' : 'Ficou para trás.',
              textAlign: TextAlign.center, style: PixelText.body(11, color: Kanagawa.springViolet1)),
        ]),
      );
}

// ---------- Ajustes ----------

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late final TextEditingController _name = TextEditingController(text: ref.read(gameControllerProvider).name);
  String? _importError;
  String? _confirm; // 'missions' | 'reset'

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _import(ImportMode mode) async {
    final err = await importCalendar(context, ref, mode);
    if (mounted) setState(() => _importError = err);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ASTRONAUTA', style: PixelText.display(10)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 24,
            style: PixelText.body(16),
            decoration: pixelInput('Nome'),
          ),
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
        ]),
      ),
      const SizedBox(height: 14),
      const _GooglePanel(),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('CALENDÁRIO', style: PixelText.display(10)),
          const SizedBox(height: 6),
          Text('Importe um arquivo .ics, .cal ou .csv. "Somar" mantém suas missões; "Substituir" troca todas.',
              style: PixelText.body(14, color: Kanagawa.springViolet1)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            PixelButton(label: 'Importar e somar', onPressed: () => _import(ImportMode.add)),
            PixelButton(label: 'Importar e substituir', color: Kanagawa.surimiOrange, onPressed: () => _import(ImportMode.replace)),
          ]),
          ErrorText(_importError),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Row(children: [
          Expanded(child: Text('SOM', style: PixelText.display(10))),
          Switch(
            value: s.sound,
            activeThumbColor: Kanagawa.carpYellow,
            onChanged: (v) {
              ctrl.apply((g) => g.sound = v);
              if (v) Sfx.click.play();
            },
          ),
        ]),
      ),
      const SizedBox(height: 14),
      PixelPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ZONA DE PERIGO', style: PixelText.display(10, color: Kanagawa.waveRed)),
          const SizedBox(height: 10),
          if (_confirm == null)
            Wrap(spacing: 8, runSpacing: 8, children: [
              PixelButton(
                label: 'Apagar todas as missões',
                color: Kanagawa.sumiInk5,
                textColor: Kanagawa.fujiWhite,
                onPressed: () => setState(() => _confirm = 'missions'),
              ),
              PixelButton(
                label: 'Zerar o jogo',
                color: Kanagawa.autumnRed,
                textColor: Kanagawa.fujiWhite,
                onPressed: () => setState(() => _confirm = 'reset'),
              ),
            ])
          else
            ConfirmBar(
              text: _confirm == 'missions'
                  ? 'Apagar todas as missões? O progresso fica.'
                  : 'Zerar tudo? XP, moedas, cursos e itens somem.',
              yesLabel: _confirm == 'missions' ? 'Apagar' : 'Zerar',
              onNo: () => setState(() => _confirm = null),
              onYes: () async {
                final what = _confirm;
                setState(() => _confirm = null);
                Sfx.delete.play();
                if (what == 'missions') {
                  ctrl.apply((g) => g.missions = []);
                  showToast(context, 'Missões apagadas');
                } else {
                  await ctrl.reset();
                }
              },
            ),
        ]),
      ),
    ]);
  }
}

class _GooglePanel extends ConsumerWidget {
  const _GooglePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final connected = s.calendarUrl != null;
    final synced = s.missions.where((m) => m.synced).length;
    final last = s.lastSync == null ? null : DateTime.fromMillisecondsSinceEpoch(s.lastSync!);
    return PixelPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('GOOGLE AGENDA', style: PixelText.display(10)),
        const SizedBox(height: 6),
        Text(
          connected
              ? 'Conectado. $synced missões vêm da agenda.'
                  '${last != null ? ' Última sincronização: ${two(last.day)}/${two(last.month)} às ${two(last.hour)}:${two(last.minute)}.' : ''}'
                  ' Para mudar uma missão da agenda, mude no Google Agenda e sincronize.'
              : 'Conecte sua agenda do Google para que os eventos virem missões. O app sincroniza toda vez que abre.',
          style: PixelText.body(14, color: Kanagawa.springViolet1),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (connected) ...[
            PixelButton(label: 'Sincronizar agenda', color: Kanagawa.springBlue, onPressed: () => syncOrConnect(context, ref)),
            PixelButton(label: 'Trocar endereço', color: Kanagawa.sumiInk5, textColor: Kanagawa.fujiWhite, onPressed: () => openGoogleConnect(context)),
            PixelButton(
              label: 'Desconectar',
              color: Kanagawa.sumiInk5,
              textColor: Kanagawa.fujiWhite,
              sound: false,
              onPressed: () {
                disconnectGoogleCalendar(ref);
                showToast(context, 'Google Agenda desconectado. As missões continuam.');
              },
            ),
          ] else
            PixelButton(label: 'Conectar Google Agenda', color: Kanagawa.springBlue, onPressed: () => openGoogleConnect(context)),
        ]),
      ]),
    );
  }
}
