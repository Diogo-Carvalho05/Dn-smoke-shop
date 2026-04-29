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
  preco_promocao numeric(10,2) default null check (preco_promocao is null or preco_promocao >= 0),
  isenta_taxa_entrega boolean not null default false,
  criado_em timestamptz default now()
);
-- Migrations safe para quem ja tem a tabela criada:
alter table produtos add column if not exists preco_promocao numeric(10,2) default null;
alter table produtos add column if not exists isenta_taxa_entrega boolean not null default false;
create index if not exists idx_produtos_ativo on produtos(ativo);
create index if not exists idx_produtos_promocao on produtos(preco_promocao) where preco_promocao is not null;

create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_nome text not null,
  cliente_telefone text not null,
  endereco jsonb not null,
  itens jsonb not null,
  subtotal numeric(10,2) not null default 0,
  taxa_entrega numeric(10,2) not null default 0,
  total numeric(10,2) not null,
  forma_pagamento text not null,
  troco_para numeric(10,2),
  status text not null default 'pendente',  -- pendente | confirmado | saiu_entrega | entregue | cancelado
  motivo_cancelamento text,
  criado_em timestamptz default now(),
  confirmado_em timestamptz,
  saiu_entrega_em timestamptz,
  entregue_em timestamptz
);
-- Migration safe pra quem ja tem a tabela criada:
alter table pedidos add column if not exists motivo_cancelamento text;
alter table pedidos add column if not exists saiu_entrega_em timestamptz;
alter table pedidos add column if not exists subtotal numeric(10,2) not null default 0;
alter table pedidos add column if not exists taxa_entrega numeric(10,2) not null default 0;
create index if not exists idx_pedidos_status on pedidos(status);
create index if not exists idx_pedidos_criado on pedidos(criado_em desc);

-- Configuracoes globais da loja (sempre uma unica linha, id = 1)
create table if not exists config_loja (
  id integer primary key default 1 check (id = 1),
  taxa_entrega_ativa boolean not null default false,
  taxa_entrega_valor numeric(10,2) not null default 0
);
insert into config_loja (id) values (1) on conflict (id) do nothing;

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
alter table config_loja enable row level security;

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

-- CONFIG_LOJA: qualquer um le (checkout precisa), so authenticated edita
drop policy if exists config_loja_select_public on config_loja;
drop policy if exists config_loja_update_auth on config_loja;
create policy config_loja_select_public on config_loja for select to public using (true);
create policy config_loja_update_auth on config_loja for update to authenticated using (true);

-- ---------- GRANTS (necessario alem das policies de RLS) ----------
grant usage on schema public to anon, authenticated;
grant select on produtos to anon, authenticated;
grant insert, update, delete on produtos to authenticated;
grant insert on pedidos to anon, authenticated;
grant select, update on pedidos to authenticated;
grant select, insert, update, delete on vendas_pdv to authenticated;
grant select on config_loja to anon, authenticated;
grant update on config_loja to authenticated;

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

-- Cria pedido E reserva estoque atomicamente (chamado pelo checkout do cliente).
-- Valida ativo + estoque, busca preco/nome do banco (ignora o que vier no payload),
-- insere o pedido e subtrai o estoque. Tudo numa transacao: qualquer falha reverte tudo.
--
-- Payload esperado (jsonb):
--   { "id": "uuid", "cliente_nome": "...", "cliente_telefone": "...",
--     "endereco": { "cep":"...", "rua":"...", "numero":"...",
--                   "complemento":"...", "bairro":"...", "cidade":"..." },
--     "itens": [ { "produto_id": "uuid", "quantidade": 2 }, ... ],
--     "forma_pagamento": "pix|cartao|dinheiro",
--     "troco_para": null }
create or replace function criar_pedido(payload jsonb)
returns uuid language plpgsql security definer as $$
declare
  p_id           uuid;
  item_in        jsonb;
  prod           record;
  qtd            int;
  preco_efetivo  numeric;
  itens_final    jsonb := '[]'::jsonb;
  total_calc     numeric := 0;
begin
  -- Extrai o id ou gera um novo
  p_id := coalesce((payload->>'id')::uuid, gen_random_uuid());

  -- Valida e reserva cada item
  for item_in in select * from jsonb_array_elements(payload->'itens') loop
    qtd := ((item_in->>'quantidade')::int);
    if qtd <= 0 then
      raise exception 'Quantidade invalida para produto %', item_in->>'produto_id';
    end if;

    select id, nome, preco, preco_promocao, estoque, ativo
      into prod
      from produtos
      where id = (item_in->>'produto_id')::uuid
      for update; -- bloqueia a linha ate o fim da transacao (evita race condition)

    if not found then
      raise exception 'Produto nao encontrado: %', item_in->>'produto_id';
    end if;
    if not prod.ativo then
      raise exception 'Produto "%" nao esta mais disponivel.', prod.nome;
    end if;
    if prod.estoque < qtd then
      raise exception 'Estoque insuficiente para "%". Disponivel: %.', prod.nome, prod.estoque;
    end if;

    -- Subtrai estoque
    update produtos set estoque = estoque - qtd where id = prod.id;

    -- Usa preco promocional se disponivel e menor que o preco normal
    preco_efetivo := case
      when prod.preco_promocao is not null and prod.preco_promocao < prod.preco
        then prod.preco_promocao
      else prod.preco
    end;

    -- Monta item com preco/nome do banco
    itens_final := itens_final || jsonb_build_object(
      'produto_id', prod.id,
      'nome',       prod.nome,
      'preco',      preco_efetivo,
      'quantidade', qtd
    );
    total_calc := total_calc + (preco_efetivo * qtd);
  end loop;

  -- Insere o pedido com preco calculado pelo banco
  insert into pedidos (
    id, cliente_nome, cliente_telefone, endereco,
    itens, subtotal, taxa_entrega, total, forma_pagamento, troco_para
  ) values (
    p_id,
    payload->>'cliente_nome',
    payload->>'cliente_telefone',
    payload->'endereco',
    itens_final,
    total_calc,
    coalesce((payload->>'taxa_entrega')::numeric, 0),
    total_calc + coalesce((payload->>'taxa_entrega')::numeric, 0),
    payload->>'forma_pagamento',
    nullif(payload->>'troco_para', '')::numeric
  );

  return p_id;
end; $$;

-- Devolve estoque ao cancelar pedido (apenas admin)
create or replace function devolver_estoque_pedido(p_pedido_id uuid)
returns void language plpgsql security definer as $$
declare
  item         jsonb;
  pedido_itens jsonb;
  p_status     text;
begin
  select itens, status into pedido_itens, p_status
    from pedidos where id = p_pedido_id;

  if pedido_itens is null then return; end if;

  -- So devolve se o pedido ainda nao foi entregue (evitar dupla devolucao)
  if p_status = 'entregue' then return; end if;

  for item in select * from jsonb_array_elements(pedido_itens) loop
    update produtos
      set estoque = estoque + (item->>'quantidade')::int
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

-- baixar_estoque_pedido mantida por compatibilidade mas nao e mais usada pelo fluxo online
create or replace function baixar_estoque_pedido(p_pedido_id uuid)
returns void language plpgsql security definer as $$
begin
  -- Fluxo novo: estoque ja e reservado em criar_pedido(). Esta funcao e no-op.
  return;
end; $$;

-- GRANTs
grant execute on function criar_pedido(jsonb)          to anon, authenticated;
grant execute on function devolver_estoque_pedido(uuid) to authenticated;
grant execute on function baixar_estoque_pedido(uuid)   to authenticated;
grant execute on function baixar_estoque_pdv(jsonb)     to authenticated;
