/// Projeto Supabase que guarda o progresso na nuvem.
///
/// A chave abaixo é a chave pública (anon / publishable) do projeto: ela
/// pode ficar no código, porque cada pessoa só lê e grava a própria linha
/// (regras de segurança em `supabase/schema.sql`).
///
/// Também dá para passar no build:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...`
class SyncConfig {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const anonKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}
