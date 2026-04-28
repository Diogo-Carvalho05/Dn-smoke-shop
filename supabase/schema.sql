-- =============================================================
-- Dn Smoke Shop - Schema completo com Supabase Auth + RLS
-- Rodar no SQL Editor: https://supabase.com/dashboard/project/_/sql
-- =============================================================

create extension if not exists "pgcrypto";

-- ---------- TABELAS ----------
create table if not exists produtos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text,
  preco numeric(10,2) not null check (preco >= 0),
  estoque integer not null default 0 check (estoque >= 0),
  imagem_url text,
  ativo boolean not null default true,
  criado_em timestamptz default now()
);
create index if not exists idx_produtos_ativo on produtos(ativo);

create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_nome text not null,
  cliente_telefone text not null,
  endereco jsonb not null,
  itens jsonb not null,
  total numeric(10,2) not null,
  forma_pagamento text not null,
  troco_para numeric(10,2),
  status text not null default 'pendente',
  criado_em timestamptz default now(),
  confirmado_em timestamptz,
  entregue_em timestamptz
);
create index if not exists idx_pedidos_status on pedidos(status);
create index if not exists idx_pedidos_criado on pedidos(criado_em desc);

create table if not exists vendas_pdv (
  id uuid primary key default gen_random_uuid(),
  itens jsonb not null,
  total numeric(10,2) not null,
  forma_pagamento text not null,
  admin_id uuid references auth.users(id),
  criado_em timestamptz default now()
);
create index if not exists idx_vendas_pdv_criado on vendas_pdv(criado_em desc);

-- ---------- RLS ----------
alter table produtos enable row level security;
alter table pedidos enable row level security;
alter table vendas_pdv enable row level security;

-- PRODUTOS: anon ve so ativos; authenticated ve tudo e edita
drop policy if exists produtos_select_anon on produtos;
drop policy if exists produtos_select_auth on produtos;
drop policy if exists produtos_insert_auth on produtos;
drop policy if exists produtos_update_auth on produtos;
drop policy if exists produtos_delete_auth on produtos;

create policy produtos_select_anon on produtos for select to anon using (ativo = true);
create policy produtos_select_auth on produtos for select to authenticated using (true);
create policy produtos_insert_auth on produtos for insert to authenticated with check (true);
create policy produtos_update_auth on produtos for update to authenticated using (true);
create policy produtos_delete_auth on produtos for delete to authenticated using (true);

-- PEDIDOS: qualquer um (anon ou logado) cria pedido; authenticated le e atualiza
drop policy if exists pedidos_insert_anon on pedidos;
drop policy if exists pedidos_insert_public on pedidos;
drop policy if exists pedidos_select_auth on pedidos;
drop policy if exists pedidos_update_auth on pedidos;

create policy pedidos_insert_public on pedidos for insert to public with check (true);
create policy pedidos_select_auth on pedidos for select to authenticated using (true);
create policy pedidos_update_auth on pedidos for update to authenticated using (true);

-- VENDAS_PDV: so authenticated
drop policy if exists vendas_pdv_all_auth on vendas_pdv;
create policy vendas_pdv_all_auth on vendas_pdv for all to authenticated using (true) with check (true);

-- ---------- STORAGE ----------
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do nothing;

drop policy if exists "produtos_read_public" on storage.objects;
drop policy if exists "produtos_write_auth" on storage.objects;
drop policy if exists "produtos_delete_auth" on storage.objects;

create policy "produtos_read_public" on storage.objects for select to public using (bucket_id = 'produtos');
create policy "produtos_write_auth" on storage.objects for insert to authenticated with check (bucket_id = 'produtos');
create policy "produtos_delete_auth" on storage.objects for delete to authenticated using (bucket_id = 'produtos');

-- ---------- FUNCOES (RPCs) ----------
-- Baixa estoque ao marcar pedido entregue
create or replace function baixar_estoque_pedido(p_pedido_id uuid)
returns void language plpgsql security definer as $$
declare
  item jsonb;
  pedido_itens jsonb;
begin
  select itens into pedido_itens from pedidos where id = p_pedido_id;
  if pedido_itens is null then return; end if;
  for item in select * from jsonb_array_elements(pedido_itens) loop
    update produtos
      set estoque = greatest(0, estoque - (item->>'quantidade')::int)
      where id = (item->>'produto_id')::uuid;
  end loop;
end; $$;

-- Baixa estoque numa venda PDV (chamada com array de itens)
create or replace function baixar_estoque_pdv(p_itens jsonb)
returns void language plpgsql security definer as $$
declare
  item jsonb;
begin
  for item in select * from jsonb_array_elements(p_itens) loop
    update produtos
      set estoque = greatest(0, estoque - (item->>'quantidade')::int)
      where id = (item->>'produto_id')::uuid;
  end loop;
end; $$;

-- Concede execucao a authenticated (admin)
grant execute on function baixar_estoque_pedido(uuid) to authenticated;
grant execute on function baixar_estoque_pdv(jsonb) to authenticated;
