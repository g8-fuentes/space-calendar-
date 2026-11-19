-- Dev Routine: tabela do progresso na nuvem.
-- Cole tudo no Supabase: SQL Editor > New query > Run.

create table if not exists public.game_states (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

-- Cada pessoa só enxerga e altera a própria linha.
alter table public.game_states enable row level security;

drop policy if exists "ler o proprio progresso" on public.game_states;
create policy "ler o proprio progresso" on public.game_states
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "criar o proprio progresso" on public.game_states;
create policy "criar o proprio progresso" on public.game_states
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "atualizar o proprio progresso" on public.game_states;
create policy "atualizar o proprio progresso" on public.game_states
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update on public.game_states to authenticated;
