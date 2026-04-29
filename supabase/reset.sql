-- =============================================================
-- Dn Smoke Shop - RESET COMPLETO DO BANCO
-- =============================================================
-- ATENCAO: Apaga TODOS os dados (produtos, pedidos, vendas, imagens).
-- Use isso ANTES de entregar o site pra outra pessoa, pra ela receber
-- o sistema zerado.
--
-- Como rodar:
--   1. Supabase Dashboard -> SQL Editor -> New query
--   2. Cola este arquivo inteiro -> Run
--
-- O que NAO e apagado:
--   - Estrutura das tabelas (continua tudo configurado)
--   - RLS, policies, RPCs, GRANTs
--   - Bucket de storage (so o conteudo dele)
--   - Usuarios admin (auth.users) -> ver bloco opcional no fim
-- =============================================================

begin;

-- 1. Limpa todos os pedidos online
truncate table pedidos restart identity cascade;

-- 2. Limpa todas as vendas do PDV
truncate table vendas_pdv restart identity cascade;

-- 3. Limpa o catalogo de produtos
truncate table produtos restart identity cascade;

-- 4. Limpa as imagens enviadas pro Storage (bucket "produtos")
delete from storage.objects where bucket_id = 'produtos';

commit;

-- =============================================================
-- OPCIONAL: apagar tambem o usuario admin que voce criou.
-- Descomente as linhas abaixo so se quiser entregar o site sem
-- nenhum login pre-cadastrado (o novo dono cria o admin dele).
-- =============================================================
-- delete from auth.users;