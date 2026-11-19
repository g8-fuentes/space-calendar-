import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rotina_quest/core/sync/cloud_client.dart';
import 'package:rotina_quest/core/time/clock.dart';
import 'package:rotina_quest/features/game/data/datasources/sync_local_datasource.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/repositories/game_repository.dart';
import 'package:rotina_quest/features/game/presentation/controllers/game_providers.dart';
import 'package:rotina_quest/features/game/presentation/controllers/sync_controller.dart';

class _MemoryRepo implements GameRepository {
  GameState? saved;
  @override
  Future<void> clear() async => saved = null;
  @override
  Future<GameState> load() async => saved ?? GameState.initial('2026-10-21');
  @override
  Future<void> save(GameState state) async => saved = state;
}

http.Response _json(Object body, int status) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// Supabase de mentira: uma conta e uma linha.
class _FakeCloud {
  Map<String, Object?>? row;
  int version = 0;
  int pushes = 0;

  http.Client get client => MockClient((req) async {
        final path = req.url.path;
        if (path.startsWith('/auth/v1/token') || path == '/auth/v1/signup') {
          return http.Response(
              jsonEncode({
                'access_token': 'tok',
                'refresh_token': 'ref',
                'expires_in': 3600,
                'user': {'email': 'gui@example.com'},
              }),
              200);
        }
        if (path == '/rest/v1/game_states' && req.method == 'GET') {
          return _json(row == null ? [] : [row], 200);
        }
        if (path == '/rest/v1/game_states' && req.method == 'POST') {
          pushes++;
          final body = jsonDecode(req.body) as Map<String, Object?>;
          row = {'state': body['state'], 'updated_at': 'v${++version}'};
          return _json([row], 201);
        }
        return http.Response('{}', 404);
      });
}

ProviderContainer _container(_FakeCloud cloud, GameState initial, SyncStore store) => ProviderContainer(overrides: [
      clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 21, 10))),
      gameRepositoryProvider.overrideWithValue(_MemoryRepo()),
      initialGameStateProvider.overrideWithValue(initial),
      syncStoreProvider.overrideWithValue(store),
      cloudClientProvider
          .overrideWithValue(CloudClient(url: 'https://x.supabase.co', anonKey: 'k', client: cloud.client)),
    ]);

GameState _played() => GameState.initial('2026-10-01')
  ..name = 'Gui'
  ..onboarded = true
  ..missions.add(Mission(id: 'a', title: 'Academia', days: [2], start: '07:00', end: '08:00'))
  ..week('2026-10-19').done['a@2'] = const DoneRecord(day: 2, title: 'Academia', at: 1);

void main() {
  test('primeiro login envia o que já estava no celular', () async {
    final cloud = _FakeCloud();
    final c = _container(cloud, _played(), MemorySyncStore());
    addTearDown(c.dispose);
    final err = await c.read(syncProvider.notifier).signIn('gui@example.com', 'segredo', create: false);
    expect(err, isNull);
    final sent = cloud.row!['state']! as Map;
    expect(sent['name'], 'Gui');
    expect((sent['missions'] as List).length, 1);
  });

  test('aparelho novo recebe o progresso da nuvem', () async {
    final cloud = _FakeCloud()..row = {'state': _played().toJson(), 'updated_at': 'v0'};
    final c = _container(cloud, GameState.initial('2026-10-21'), MemorySyncStore());
    addTearDown(c.dispose);
    await c.read(syncProvider.notifier).signIn('gui@example.com', 'segredo', create: false);
    final s = c.read(gameControllerProvider);
    expect(s.onboarded, isTrue);
    expect(s.name, 'Gui');
    expect(s.weeks['2026-10-19']!.done.keys, ['a@2']);
    expect(cloud.pushes, 0);
  });

  test('dois aparelhos com dados: junta os dois', () async {
    final pc = _played()
      ..missions.add(Mission(id: 'b', title: 'Inglês', days: [1], start: '19:00', end: '20:00'))
      ..week('2026-10-19').done['b@1'] = const DoneRecord(day: 1, title: 'Inglês', at: 2);
    final cloud = _FakeCloud()..row = {'state': pc.toJson(), 'updated_at': 'v0'};
    final phone = _played()..todos.add(Todo(id: 't', text: 'Ler'));
    final c = _container(cloud, phone, MemorySyncStore());
    addTearDown(c.dispose);
    await c.read(syncProvider.notifier).signIn('gui@example.com', 'segredo', create: false);
    final s = c.read(gameControllerProvider);
    expect(s.missions.length, 2);
    expect(s.todos.length, 1);
    expect(s.weeks['2026-10-19']!.done.keys.toSet(), {'a@2', 'b@1'});
    expect(((cloud.row!['state']! as Map)['missions'] as List).length, 2);
  });

  test('mudança local sobe; mudança de outro aparelho desce', () async {
    final cloud = _FakeCloud();
    final store = MemorySyncStore();
    final c = _container(cloud, _played(), store);
    addTearDown(c.dispose);
    final sync = c.read(syncProvider.notifier);
    await sync.signIn('gui@example.com', 'segredo', create: false);

    c.read(gameControllerProvider.notifier).apply((s) => s.name = 'Neo');
    await sync.syncNow();
    expect((cloud.row!['state']! as Map)['name'], 'Neo');
    expect(store.dirty, isFalse);

    // outro aparelho troca o nome direto na nuvem
    final other = Map<String, Object?>.from(cloud.row!['state']! as Map)..['name'] = 'Trinity';
    cloud.row = {'state': other, 'updated_at': 'v99'};
    await sync.syncNow();
    expect(c.read(gameControllerProvider).name, 'Trinity');
    expect(store.base, 'v99');
  });
}
