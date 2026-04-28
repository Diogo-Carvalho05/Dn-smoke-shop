# Dn Smoke Shop

Sistema de gestao de vendas e produtos para tabacaria de cigarro eletronico.

- **Frontend:** HTML5 + TailwindCSS (via CDN) + JS vanilla (mobile-first, responsivo)
- **Backend:** Vercel Serverless Functions (Python)
- **Banco de dados:** Supabase (PostgreSQL + Storage para imagens)
- **Hospedagem:** Vercel (free tier)
- **Cores:** preto / branco

## Funcionalidades

### Cliente (sem login)
- Lista de produtos com foto, preco e estoque
- Carrinho persistente no navegador
- Checkout com endereco (busca por CEP via ViaCEP, numero obrigatorio)
- Forma de pagamento: cartao, PIX ou dinheiro (com troco)
- Pedido enviado pro WhatsApp da loja **e** salvo no banco

### Admin (com login)
- CRUD de produtos (com upload de foto)
- Gerenciamento de pedidos online (confirmar / marcar entregue / cancelar)
- Estoque baixa automaticamente quando o admin marca o pedido como entregue
- PDV (venda presencial) — baixa estoque na hora
- Relatorios filtrados por periodo, separando online / PDV / geral

---

## Estrutura de pastas

```
Dn-smoke-shop/
├── api/                          # Vercel Serverless Functions (Python)
│   ├── _lib/
│   │   ├── __init__.py
│   │   ├── supabase_client.py
│   │   └── auth_guard.py
│   ├── auth.py
│   ├── produtos.py
│   ├── pedidos.py
│   ├── vendas_pdv.py
│   ├── relatorios.py
│   ├── upload.py
│   └── config_publico.py
├── public/                       # frontend estatico
│   ├── index.html                # loja
│   ├── carrinho.html
│   ├── checkout.html
│   ├── admin/
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   ├── pedidos.html
│   │   ├── pdv.html
│   │   ├── relatorios.html
│   │   └── _nav.html
│   └── js/
│       ├── api.js
│       └── carrinho.js
├── supabase/
│   ├── schema.sql                # tabelas + indices + RLS
│   └── seed_admin.sql            # cria conta admin
├── requirements.txt              # supabase, PyJWT, bcrypt
├── vercel.json
└── README.md
```

---

## Passo a passo de instalacao

### 1. Pre-requisitos
- Conta no [GitHub](https://github.com/), [Supabase](https://supabase.com/) e [Vercel](https://vercel.com/)

### 2. Clonar
```bash
git clone https://github.com/SEU-USUARIO/Dn-smoke-shop.git
cd Dn-smoke-shop
```

### 3. Configurar Supabase
1. Crie projeto em https://supabase.com/dashboard
2. **Project Settings -> API**: anote `Project URL` e a key `service_role`
3. **SQL Editor** -> cole `supabase/schema.sql` -> **Run**
4. **Storage -> New bucket** -> nome `produtos` -> marque **Public bucket** -> Save
5. **SQL Editor** -> abra `supabase/seed_admin.sql`, troque a senha pela sua (texto simples) e o email se quiser -> Run

### 4. Deploy na Vercel
1. https://vercel.com/new -> importe o repo do GitHub
2. Em **Environment Variables** cadastre as 5:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `JWT_SECRET` (gere uma string aleatoria longa, ex: `python -c "import secrets;print(secrets.token_hex(32))"`)
   - `LOJA_WHATSAPP` (ex: `5511999999999`)
   - `LOJA_NOME` (ex: `Dn Smoke Shop`)
3. **Deploy**

A partir daqui, todo `git push` na `main` faz redeploy automatico.

---

## Acesso

- **Loja:** `https://seu-projeto.vercel.app/`
- **Admin:** `https://seu-projeto.vercel.app/admin/login.html`

## Como funciona

### Cliente
1. Loja -> carrinho -> checkout (CEP via ViaCEP, numero obrigatorio).
2. Confirma -> pedido salvo no Supabase **e** WhatsApp da loja abre com mensagem pronta.

### Admin
1. Login em `/admin/login.html` (JWT 12h salvo no `localStorage`).
2. **Produtos:** cria/edita/remove, upload de fotos.
3. **Pedidos:** `pendente -> confirmado -> entregue` (estoque baixa ao marcar entregue).
4. **PDV:** venda no balcao (estoque baixa imediato).
5. **Relatorios:** filtra por periodo, ve online + PDV + total geral.

## Seguranca

- A `SUPABASE_SERVICE_ROLE_KEY` so existe nas Environment Variables da Vercel — nunca chega no navegador.
- RLS ativado em todas as tabelas, sem policies para `anon`.
- Login admin: o sistema aceita senha em **texto simples** (mais simples) ou **bcrypt hash** (`$2...`). Pra usar bcrypt, gere com `python -c "import bcrypt; print(bcrypt.hashpw(b'SUA_SENHA', bcrypt.gensalt()).decode())"` e cole no `senha_hash` do admin.
- Rotas admin verificam token JWT.
