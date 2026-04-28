// =====================================================================
// Configuracao do Supabase e da loja.
// Anon key e PUBLICA por design — segura quando usada com RLS ativado.
// =====================================================================

const SUPABASE_URL = "https://jiabfobolyiebubvjwnj.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppYWJmb2JvbHlpZWJ1YnZqd25qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNjQzODAsImV4cCI6MjA5Mjk0MDM4MH0.t685JOE9W0Swt0c4aE_gI8Q92Tyc2Nj7S1N2keYHHqg";

const LOJA = {
  nome: "Dn Smoke Shop",
  whatsapp: "5518997259973", // formato internacional, so numeros
};

// Cliente Supabase global (usa o SDK carregado via CDN no <head>)
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helpers globais
const fmtBRL = (v) => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
