# Sincronização entre aparelhos

O progresso (missões, semanas, níveis, tarefas e a chama de Disciplina) fica salvo no aparelho e,
com login, também numa tabela no [Supabase](https://supabase.com) (plano grátis). Assim o mesmo
progresso aparece no app Android, no navegador do computador e no PWA instalado no celular.

## Configurar (uma vez só)

1. Crie uma conta em supabase.com e um projeto novo (qualquer nome, região São Paulo).
2. No projeto, abra **SQL Editor > New query**, cole o conteúdo de [`supabase/schema.sql`](../supabase/schema.sql)
   e clique em **Run**.
3. Em **Authentication > Sign In / Providers > Email**, desligue **Confirm email** (assim a conta
   já entra ao ser criada). Se preferir deixar ligado, em **Authentication > URL Configuration**
   coloque `https://g8-fuentes.github.io/space-calendar-/` como *Site URL*.
4. Em **Project Settings > API** (ou **Connect**), copie a **Project URL** e a chave pública
   (**anon** ou **publishable**). Nunca use a chave `service_role`/`secret`.
5. No GitHub: **Settings > Secrets and variables > Actions > Variables > New repository variable**:
   - `SUPABASE_URL` = a Project URL
   - `SUPABASE_KEY` = a chave pública
6. No GitHub: **Settings > Pages > Source: GitHub Actions**.
7. Rode de novo as ações **Web (PWA)** e **Android APK** (ou envie qualquer mudança para `main`).

## Como funciona

- Sem login, nada muda: o app salva só no aparelho.
- No primeiro login de um aparelho, o que já estava nele sobe para a nuvem. Se a nuvem já tinha
  progresso de outro aparelho, os dois são juntados: nenhuma missão concluída, dia pulado,
  semana explorada ou tarefa se perde.
- Cada mudança sobe em 2 segundos. Ao abrir o app, ao voltar para ele e a cada 2 minutos,
  ele busca o que mudou nos outros aparelhos.
- Sem internet, o app continua funcionando e as mudanças sobem quando a conexão voltar.
