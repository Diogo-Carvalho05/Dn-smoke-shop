-- =========================================================
-- Dn Smoke Shop - Schema Supabase
-- Rodar no SQL Editor do Supabase: https://supabase.com/dashboard/project/_/sql
-- =========================================================

-- Extensoes
create extension if not exists "pgcrypto";

-- ---------- ADMINS ----------
create table if not exists admins (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  senha_hash text not null,
  criado_em timestamptz default now()
);

-- ---------- PRODUTOS ----------
create table if not exists produtos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text,
  preco numeric(10,2) not null check (preco >= 0),
  estoque integer not null default 0 check (estoque >= 0),
  imagem_url text,
  ativo boolean not null default true,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);
create index if not exists idx_produtos_ativo on produtos(ativo);

-- ---------- PEDIDOS (vendas online) ----------
-- status: pendente | confirmado | entregue | cancelado
create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_nome text not null,
  cliente_telefone text not null,
  endereco jsonb not null,            -- { cep, rua, numero, complemento, bairro, cidade }
  itens jsonb not null,               -- [ { produto_id, nome, preco, quantidade } ]
  total numeric(10,2) not null,
  forma_pagamento text not null,      -- cartao | pix | dinheiro
  troco_para numeric(10,2),           -- null se nao for dinheiro
  status text not null default 'pendente',
  criado_em timestamptz default now(),
  confirmado_em timestamptz,
  entregue_em timestamptz
);
create index if not exists idx_pedidos_status on pedidos(status);
create index if not exists idx_pedidos_criado on pedidos(criado_em desc);

-- ---------- VENDAS PDV (balcao) ----------
create table if not exists vendas_pdv (
  id uuid primary key default gen_random_uuid(),
  itens jsonb not null,
  total numeric(10,2) not null,
  forma_pagamento text not null,
  admin_id uuid references admins(id),
  criado_em timestamptz default now()
);
create index if not exists idx_vendas_pdv_criado on vendas_pdv(criado_em desc);

-- ---------- RLS ----------
-- Como toda comunicacao passa pelas serverless functions usando a service_role key,
-- ativamos RLS e nao criamos policies para o anon. Ninguem acessa direto.
alter table admins enable row level security;
alter table produtos enable row level security;
alter table pedidos enable row level security;
alter table vendas_pdv enable row level security;

-- ---------- STORAGE ----------
-- Cria bucket "produtos" para imagens. Rodar manualmente em Storage > New bucket
-- com nome "produtos" e Public = true (assim a tag <img> consegue carregar a URL).
