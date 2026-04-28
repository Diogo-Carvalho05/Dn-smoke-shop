# Dn Smoke Shop

Sistema de gestao de vendas e produtos para tabacaria de cigarro eletronico.

- **Frontend:** HTML5 + TailwindCSS + JS vanilla (mobile-first, responsivo)
- **Backend:** Vercel Serverless Functions (Python) — sem servidor pra gerenciar
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
│   │   ├── supabase_client.py    # cliente Supabase com SERVICE_ROLE
│   │   └── auth_guard.py         # JWT (gerar/verificar)
│   ├── auth.py                   # POST /api/auth          login admin
│   ├── produtos.py               # GET/POST/PUT/DELETE     CRUD produtos
│   ├── pedidos.py                # POST publico / GET PUT admin
│   ├── vendas_pdv.py             # POST registra venda balcao + baixa estoque
│   ├── relatorios.py             # GET vendas por periodo
│   ├── upload.py                 # POST imagem -> Supabase Storage
│   └── config_publico.py         # GET nome da loja + numero whatsapp
├── public/                       # estatico servido pela Vercel
│   ├── index.html                # loja (cliente)
│   ├── carrinho.html
│   ├── checkout.html
│   ├── admin/
│   │   ├── login.html
│   │   ├── dashboard.html        # produtos + estoque
│   │   ├── pedidos.html
│   │   ├── pdv.html
│   │   ├── relatorios.html
│   │   └── _nav.html             # snippet de navegacao
│   ├── css/
│   │   ├── input.css             # fonte Tailwind
│   │   └── output.css            # gerado pelo build (nao commitar)
│   └── js/
│       ├── api.js                # fetch wrapper + token
│       └── carrinho.js           # carrinho em localStorage
├── supabase/
│   ├── schema.sql                # tabelas + indices + RLS
│   └── seed_admin.sql            # cria conta admin unica
├── .env.example
├── .gitignore
├── package.json                  # build do Tailwind
├── tailwind.config.js
├── requirements.txt              # supabase-py, PyJWT, bcrypt
├── vercel.json                   # config Vercel
└── README.md
```

---

## Passo a passo de instalacao

### 1. Pre-requisitos

- [Node.js 18+](https://nodejs.org/)
- [Python 3.11+](https://www.python.org/)
- [Git](https://git-scm.com/)
- Conta no [GitHub](https://github.com/)
- Conta no [Supabase](https://supabase.com/) (free)
- Conta na [Vercel](https://vercel.com/) (free)

### 2. Clonar o projeto

```bash
git clone https://github.com/SEU-USUARIO/Dn-smoke-shop.git
cd Dn-smoke-shop
```

### 3. Configurar Supabase

1. Acesse https://supabase.com/dashboard e crie um novo projeto.
2. Va em **Project Settings -> API** e anote:
   - `Project URL` -> sera `SUPABASE_URL`
   - `service_role` (em "Project API keys") -> sera `SUPABASE_SERVICE_ROLE_KEY`
3. Va em **SQL Editor**, cole o conteudo de `supabase/schema.sql` e clique em **Run**.
4. Va em **Storage -> New bucket**, nome `produtos`, marque **Public bucket**, salve.
5. Crie a senha do admin localmente:
   ```bash
   pip install bcrypt
   python -c "import bcrypt; print(bcrypt.hashpw(b'SUA_SENHA', bcrypt.gensalt()).decode())" 
   
   "nao criei uma hash no momento".
   ```
   Copie o hash que aparece.
6. Edite `supabase/seed_admin.sql`, cole o hash no lugar de `<COLE_HASH_AQUI>` e mude o email se quiser.
7. Volte ao **SQL Editor** do Supabase, cole o conteudo de `seed_admin.sql` e rode.

### 4. Configurar variaveis de ambiente

Copie `.env.example` para `.env` e preencha:

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
JWT_SECRET=<gere com: python -c "import secrets;print(secrets.token_hex(32))">
LOJA_WHATSAPP=5511999999999
LOJA_NOME=Dn Smoke Shop
```

### 5. Rodar localmente

```bash
# instala Tailwind
npm install

# em um terminal: build do CSS em watch
npm run dev:css

# instala Vercel CLI (uma vez)
npm i -g vercel

# em outro terminal: roda o projeto inteiro (front + funcoes /api)
vercel dev
```

Abre em http://localhost:3000

- Loja: http://localhost:3000/
- Admin: http://localhost:3000/admin/login.html

### 6. Subir pro GitHub

```bash
git add .
git commit -m "Sistema Dn Smoke Shop"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/Dn-smoke-shop.git
git push -u origin main
```

### 7. Deploy na Vercel

1. Acesse https://vercel.com/new
2. Importe o repositorio `Dn-smoke-shop` do seu GitHub
3. Em **Environment Variables**, adicione **TODAS** as do seu `.env`:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `JWT_SECRET`
   - `LOJA_WHATSAPP`
   - `LOJA_NOME`
4. Clique em **Deploy**.
5. Pronto. A Vercel ja detecta o `vercel.json` e roda o build do Tailwind.

A partir daqui, todo `git push` na branch `main` faz redeploy automatico.

---

## Como funciona o fluxo

### Cliente
1. Entra na loja, ve produtos.
2. Adiciona ao carrinho (salva no `localStorage` do navegador).
3. Vai pro checkout, preenche nome/telefone/endereco/pagamento.
4. Ao confirmar:
   - O pedido e salvo no Supabase via `POST /api/pedidos`
   - O navegador abre o WhatsApp da loja com a mensagem ja pronta

### Admin
1. Entra em `/admin/login.html`, faz login (JWT salvo no `localStorage`).
2. **Produtos:** cria/edita/remove, faz upload de fotos.
3. **Pedidos:** ve pedidos online. Fluxo: `pendente -> confirmado -> entregue`. Quando marca entregue, **estoque baixa automatico**.
4. **PDV:** registra venda no balcao, **estoque baixa na hora**.
5. **Relatorios:** filtra por periodo, ve total online, total PDV e total geral.

---

## Seguranca

- A `SUPABASE_SERVICE_ROLE_KEY` **nunca** chega no navegador. Toda comunicacao com o Supabase passa pelas funcoes em `/api`, que rodam server-side na Vercel.
- RLS ativado em todas as tabelas (sem policies para `anon`), entao mesmo se a key vazasse o acesso direto seria bloqueado.
- Login do admin usa bcrypt + JWT (12h de validade).
- Rotas admin (`/api/produtos POST/PUT/DELETE`, `/api/pedidos GET/PUT`, `/api/vendas_pdv`, `/api/relatorios`, `/api/upload`) verificam o token JWT.

---

## Comandos uteis

```bash
# build do CSS (producao)
npm run build

# CSS em watch (desenvolvimento)
npm run dev:css

# rodar local com funcoes /api
vercel dev

# logs em producao
vercel logs
```

---

## Proximos passos sugeridos

- Pagina publica de "acompanhar pedido" pelo telefone + id curto
- Notificacao por email no novo pedido (Resend / SendGrid)
- Categoria/tag de produtos quando o catalogo crescer
- Backup automatico (Supabase ja faz, mas dump manual semanal nao machuca)
