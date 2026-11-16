-- =====================================================================
-- Minhas Despesas — esquema do banco (Supabase / PostgreSQL)
-- Rode este arquivo inteiro em: Supabase → SQL Editor → New query → Run
-- Pode ser executado de novo sem perder dados (usa IF NOT EXISTS).
-- =====================================================================

-- ---------- Tabela principal: uma linha por parcela (igual à planilha) ----------
create table if not exists public.despesas (
  id             bigint generated always as identity primary key,
  user_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  grupo          uuid not null default gen_random_uuid(),       -- liga as parcelas da mesma compra
  data_compra    date not null,
  descricao      text not null check (length(trim(descricao)) > 0),
  categoria      text not null default 'Outros',
  valor_total    numeric(14,2) not null check (valor_total >= 0),
  cartao         text not null,
  num_parcelas   integer not null default 1 check (num_parcelas between 1 and 120),
  parcela_atual  integer not null default 1 check (parcela_atual >= 1),
  valor_parcela  numeric(14,4) not null check (valor_parcela >= 0),
  mes_pagamento  date not null check (extract(day from mes_pagamento) = 1),  -- sempre dia 1 do mês
  status         text not null default 'Em Aberto' check (status in ('Pago','Em Aberto','Atrasado')),
  criado_em      timestamptz not null default now(),
  atualizado_em  timestamptz not null default now()
);

create index if not exists despesas_user_mes_idx   on public.despesas (user_id, mes_pagamento);
create index if not exists despesas_user_grupo_idx on public.despesas (user_id, grupo);
create index if not exists despesas_user_cat_idx   on public.despesas (user_id, categoria);

-- ---------- Limites de orçamento por categoria ----------
create table if not exists public.orcamentos (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  categoria  text not null,
  limite     numeric(14,2) not null check (limite > 0),
  primary key (user_id, categoria)
);

-- ---------- Atualiza "atualizado_em" automaticamente ----------
create or replace function public.tg_set_atualizado_em()
returns trigger language plpgsql as $$
begin
  new.atualizado_em := now();
  return new;
end $$;

drop trigger if exists despesas_atualizado_em on public.despesas;
create trigger despesas_atualizado_em
  before update on public.despesas
  for each row execute function public.tg_set_atualizado_em();

-- ---------- Segurança: cada usuário só enxerga e altera o que é seu ----------
alter table public.despesas   enable row level security;
alter table public.orcamentos enable row level security;

drop policy if exists "despesas_select" on public.despesas;
drop policy if exists "despesas_insert" on public.despesas;
drop policy if exists "despesas_update" on public.despesas;
drop policy if exists "despesas_delete" on public.despesas;
create policy "despesas_select" on public.despesas for select to authenticated using (user_id = auth.uid());
create policy "despesas_insert" on public.despesas for insert to authenticated with check (user_id = auth.uid());
create policy "despesas_update" on public.despesas for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "despesas_delete" on public.despesas for delete to authenticated using (user_id = auth.uid());

drop policy if exists "orcamentos_all" on public.orcamentos;
create policy "orcamentos_all" on public.orcamentos for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Visitantes sem login não têm acesso nenhum
revoke all on public.despesas   from anon;
revoke all on public.orcamentos from anon;
grant select, insert, update, delete on public.despesas   to authenticated;
grant select, insert, update, delete on public.orcamentos to authenticated;

-- =====================================================================
-- Teste rápido de RLS (opcional) — rode DEPOIS de criar seu usuário.
-- No SQL Editor você é administrador, então simulamos um visitante:
--
--   set local role anon;
--   select count(*) from public.despesas;   -- deve dar ERRO de permissão
--   reset role;
-- =====================================================================
