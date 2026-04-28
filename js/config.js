// =====================================================================
// Configuracao do Supabase e da loja.
// Anon key e PUBLICA por design — segura quando usada com RLS ativado.
// =====================================================================

const SUPABASE_URL = "https://COLE_AQUI.supabase.co";
const SUPABASE_ANON_KEY = "COLE_AQUI_A_ANON_KEY";

const LOJA = {
  nome: "Dn Smoke Shop",
  whatsapp: "5518997259973", // formato internacional, so numeros
};

// Cliente Supabase global (usa o SDK carregado via CDN no <head>)
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helpers globais
const fmtBRL = (v) => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
