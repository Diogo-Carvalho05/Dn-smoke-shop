# Dn Smoke Shop

Sistema de gestao de vendas e produtos para tabacaria de cigarro eletronico.

- **Frontend:** HTML5 + Tailwind (CDN) + JS vanilla
- **Backend:** **nenhum** — front conversa direto com Supabase
- **Auth:** Supabase Authentication
- **Banco/Storage:** Supabase
- **Hospedagem:** Vercel (so estatico, sem serverless function)

## Estrutura

```
Dn-smoke-shop/
├── index.html              # loja
├── carrinho.html
├── checkout.html
├── admin/
│   ├── login.html
│   ├── dashboard.html      # produtos + estoque
│   ├── pedidos.html
│   ├── pdv.html
│   ├── relatorios.html
│   └── _nav.html
├── js/
│   ├── config.js           # URL e anon key do Supabase + dados da loja
│   ├── auth.js             # login/logout via Supabase Auth
│   └── carrinho.js         # carrinho em localStorage
├── supabase/
│   └── schema.sql          # tabelas + RLS + funcoes (RPCs)
├── vercel.json
└── README.md
```

---

## Passo a passo (do zero)

### 1. Supabase

1. Crie projeto em https://supabase.com/dashboard
2. **SQL Editor -> New query** -> cola tudo de `supabase/schema.sql` -> **Run**.
   Isso cria tabelas, RLS policies, bucket de imagens e funcoes de baixa de estoque.
3. **Authentication -> Users -> Add user -> Create new user**:
   - Email: o seu email de admin
   - Password: a senha que voce vai usar pra logar
   - Marque **Auto Confirm User** (importante)
   - Clica em **Create user**
4. **Project Settings -> API** -> copia:
   - `Project URL`
   - `anon` `public` key (a **anon**, NAO a service_role)

### 2. Configurar o front

Abre `js/config.js` e troca os valores:

```js
const SUPABASE_URL = "https://SEU_PROJETO.supabase.co";
const SUPABASE_ANON_KEY = "eyJ...";   // a anon key, e PUBLICA, pode commitar
const LOJA = {
  nome: "Dn Smoke Shop",
  whatsapp: "5518997259973",  // seu numero, formato internacional, so digitos
};
```

A `anon key` e **publica por design**. A seguranca vem do RLS configurado no `schema.sql`: anon so faz o que voce permite (ler produtos ativos, criar pedidos). O resto exige login.

### 3. GitHub

```bash
git add .
git commit -m "Setup Supabase Auth"
git push
```

### 4. Vercel

1. https://vercel.com/new -> importa o repo do GitHub
2. **Framework Preset: Other** (NAO escolha Python/Next/etc)
3. Deixa **Build Command, Output Directory, Install Command** vazios (override OFF)
4. **NAO precisa cadastrar nenhuma Environment Variable**
5. **Deploy**

A partir daqui, todo `git push` faz redeploy automatico.

---

## Acesso

- **Loja:** `https://seu-projeto.vercel.app/`
- **Admin:** `https://seu-projeto.vercel.app/admin` (redireciona pra login)

## Fluxo

### Cliente (sem login)
1. Loja -> carrinho -> checkout (CEP via ViaCEP, numero obrigatorio).
2. Confirma -> pedido salvo no Supabase **e** WhatsApp da loja abre com mensagem pronta.

### Admin (login Supabase Auth)
1. Login em `/admin/login.html` (sessao persiste no navegador).
2. **Produtos:** cria/edita/inativa, upload de fotos pro Storage.
3. **Pedidos:** `pendente -> confirmado -> entregue`. Ao marcar entregue, o RPC `baixar_estoque_pedido` baixa o estoque.
4. **PDV:** venda no balcao, RPC `baixar_estoque_pdv` baixa estoque na hora.
5. **Relatorios:** filtra por periodo, separa online / PDV / total.

## Seguranca (RLS)

Todas as tabelas tem Row Level Security ativado:

| Tabela | anon (visitante) | authenticated (admin) |
|---|---|---|
| `produtos` | SELECT (so ativos) | SELECT/INSERT/UPDATE/DELETE |
| `pedidos` | INSERT | SELECT/UPDATE |
| `vendas_pdv` | nada | tudo |
| Storage `produtos` | leitura publica | upload/delete |

Mesmo se a anon key vazasse (e ela e publica mesmo), ninguem consegue:
- Ver produtos inativos
- Listar/editar pedidos
- Acessar PDV
- Apagar imagens

Pra criar mais admins, basta criar mais usuarios no **Authentication -> Users**.

## Adicionando outro admin

Authentication -> Users -> Add user. Pronto. Qualquer usuario autenticado pelo Supabase tem acesso de admin.
