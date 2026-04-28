-- Cria o admin unico.
-- 1) Gere o hash bcrypt da sua senha rodando localmente:
--    python -c "import bcrypt; print(bcrypt.hashpw(b'SUA_SENHA_AQUI', bcrypt.gensalt()).decode())"
-- 2) Cole o hash no lugar de <COLE_HASH_AQUI>
-- 3) Rode no SQL Editor do Supabase

insert into admins (email, senha_hash)
values ('admin@dnsmokeshop.com', '<COLE_HASH_AQUI>')
on conflict (email) do nothing;
