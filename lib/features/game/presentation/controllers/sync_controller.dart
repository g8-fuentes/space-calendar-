import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/cloud_client.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/time/week_utils.dart';
import '../../data/datasources/sync_local_datasource.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/services/state_merge.dart';
import 'game_providers.dart';

/// Injetados em `main()`; nos testes, a nuvem fica desligada.
final syncStoreProvider = Provider<SyncStore>((ref) => MemorySyncStore());
final cloudClientProvider = Provider<CloudClient?>((ref) => null);

/// Situação da sincronização, para a tela de Ajustes.
class SyncStatus {
  const SyncStatus({this.available = false, this.email, this.busy = false, this.error, this.lastSync});

  /// A nuvem está configurada neste build.
  final bool available;

  /// E-mail da conta logada (null = sem login).
  final String? email;
  final bool busy;
  final String? error;
  final DateTime? lastSync;

  bool get signedIn => email != null;

  SyncStatus copyWith(
          {String? email,
          bool clearEmail = false,
          bool? busy,
          String? error,
          bool clearError = false,
          DateTime? lastSync}) =>
      SyncStatus(
        available: available,
        email: clearEmail ? null : email ?? this.email,
        busy: busy ?? this.busy,
        error: clearError ? null : error ?? this.error,
        lastSync: lastSync ?? this.lastSync,
      );
}

final syncProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

/// Mantém o save igual em todos os aparelhos da conta.
///
/// Cada mudança local marca o save como "sujo" e, dois segundos depois,
/// sincroniza: busca o save da nuvem; se ninguém mexeu nele desde a última
/// vez, envia o local; se outro aparelho mexeu, junta os dois
/// ([mergeStates]) e envia o resultado. Ao abrir ou voltar para o app,
/// e a cada dois minutos, busca o que mudou nos outros aparelhos.
class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce, _poll;
  Future<void>? _running;
  bool _again = false;
  int _edits = 0;

  SyncStore get _store => ref.read(syncStoreProvider);
  CloudClient? get _client => ref.read(cloudClientProvider);

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _poll?.cancel();
    });
    final client = _client;
    final session = _store.session;
    if (client == null) return const SyncStatus();
    if (session != null) {
      Timer.run(() => unawaited(syncNow()));
      _poll = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(syncNow()));
    }
    return SyncStatus(available: true, email: session?.email);
  }

  /// Chamado pelo jogo a cada mudança salva no aparelho.
  void localChanged() {
    _edits++;
    _store.dirty = true;
    if (_client == null || _store.session == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
  }

  /// Entra (ou cria a conta) e junta o progresso deste aparelho com o da
  /// nuvem. Devolve uma mensagem de erro ou de aviso, ou null se deu certo.
  Future<String?> signIn(String email, String password, {required bool create}) async {
    final client = _client;
    if (client == null) return 'A sincronização não está configurada.';
    email = email.trim();
    if (!email.contains('@')) return 'Escreva um e-mail válido.';
    if (password.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = create ? await client.signUp(email, password) : await client.signIn(email, password);
      if (session == null) {
        state = state.copyWith(busy: false);
        return 'Conta criada! Abra o link de confirmação que chegou no seu e-mail e depois toque em "Entrar".';
      }
      _store.session = session;
      // Conta nova neste aparelho: o que já está nele precisa ir para a nuvem.
      _store.base = null;
      state = state.copyWith(email: session.email, busy: false);
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(syncNow()));
      await syncNow();
      return state.error;
    } on CloudException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return e.message;
    }
  }

  Future<void> signOut() async {
    final s = _store.session;
    _debounce?.cancel();
    _poll?.cancel();
    _store
      ..session = null
      ..base = null;
    state = state.copyWith(clearEmail: true, clearError: true, busy: false);
    if (s != null) await _client?.signOut(s);
  }

  /// Sincroniza agora. Chamadas durante uma sincronização ficam para logo depois.
  Future<void> syncNow() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final f = _run().whenComplete(() {
      _running = null;
      if (_again) {
        _again = false;
        unawaited(syncNow());
      }
    });
    _running = f;
    return f;
  }

  /// Depois de "Recomeçar": a nuvem passa a ter o save zerado, sem juntar
  /// com o antigo.
  Future<void> replaceCloud() async {
    _debounce?.cancel();
    try {
      final s = await _validSession();
      if (s == null) return;
      final edits = _edits;
      _store.base = await _client!.push(s, ref.read(gameControllerProvider).toJson());
      if (edits == _edits) _store.dirty = false;
      state = state.copyWith(lastSync: DateTime.now(), clearError: true);
    } on CloudException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> _run() async {
    final client = _client;
    if (client == null || _store.session == null) return;
    state = state.copyWith(busy: true);
    try {
      var session = await _validSession();
      if (session == null) {
        state = state.copyWith(busy: false);
        return;
      }
      try {
        await _syncWith(client, session);
      } on CloudException catch (e) {
        if (!e.unauthorized) rethrow;
        // Token vencido no meio do caminho: renova e tenta mais uma vez.
        session = await _validSession(forceRefresh: true);
        if (session == null) {
          state = state.copyWith(busy: false);
          return;
        }
        await _syncWith(client, session);
      }
      state = state.copyWith(busy: false, clearError: true, lastSync: DateTime.now());
    } on CloudException catch (e) {
      state = state.copyWith(
          busy: false, error: e.offline ? 'Sem internet: as mudanças sobem quando a conexão voltar.' : e.message);
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Erro ao sincronizar: $e');
    }
  }

  Future<void> _syncWith(CloudClient client, CloudSession session) async {
    final game = ref.read(gameControllerProvider.notifier);
    final remote = await client.fetch(session);
    final local = ref.read(gameControllerProvider);
    final base = _store.base;
    // Sem versão conhecida (primeiro login neste aparelho), o que houver
    // aqui conta como mudança local, para não ser perdido.
    final dirty = base == null ? !isPristine(local) : _store.dirty;
    final edits = _edits;

    Future<void> send(GameState s) async {
      _store.base = await client.push(session, s.toJson());
      if (edits == _edits) _store.dirty = false;
    }

    if (remote == null) {
      if (!isPristine(local) || base == null) await send(local);
      return;
    }
    if (remote.updatedAt == base) {
      if (dirty) await send(local);
      return;
    }
    final cloud = GameState.fromJson(remote.state, today: ymd(game.now));
    if (!dirty) {
      game.replaceFromCloud(cloud);
      _store.base = remote.updatedAt;
      if (edits == _edits) _store.dirty = false;
      return;
    }
    final merged = mergeStates(local, cloud);
    game.replaceFromCloud(merged);
    await send(merged);
  }

  /// Sessão com token válido; renova se estiver vencendo. Se a nuvem
  /// recusar a renovação, sai da conta.
  Future<CloudSession?> _validSession({bool forceRefresh = false}) async {
    final client = _client;
    final s = _store.session;
    if (client == null || s == null) return null;
    if (!forceRefresh && !s.expiringSoon) return s;
    try {
      final fresh = await client.refresh(s);
      _store.session = fresh;
      return fresh;
    } on CloudException catch (e) {
      if (e.unauthorized) {
        _store.session = null;
        _store.base = null;
        state =
            state.copyWith(clearEmail: true, busy: false, error: 'Sua sessão expirou. Entre de novo para sincronizar.');
        return null;
      }
      rethrow;
    }
  }
}

/// Usado pelo [main] para ligar a nuvem quando ela está configurada.
CloudClient? cloudClientFromConfig() =>
    SyncConfig.enabled ? CloudClient(url: SyncConfig.url, anonKey: SyncConfig.anonKey) : null;
