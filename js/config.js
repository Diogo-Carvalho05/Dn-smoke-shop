// =====================================================================
// Configuracao do Supabase e da loja.
// Anon key e PUBLICA por design — segura quando usada com RLS ativado.
// =====================================================================

const SUPABASE_URL = "https://jiabfobolyiebubvjwnj.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppYWJmb2JvbHlpZWJ1YnZqd25qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNjQzODAsImV4cCI6MjA5Mjk0MDM4MH0.t685JOE9W0Swt0c4aE_gI8Q92Tyc2Nj7S1N2keYHHqg";

// ATENCAO: troque os 2 numeros de WhatsApp abaixo pelos reais antes de
// publicar. Formato: codigo do pais + DDD + numero, so digitos. Ex: 5518999998888
const LOJA = {
  nome: "Dn Smoke Shop",
  whatsapp: "5513996305066 ",           // PRINCIPAL (dono) — pedidos vao primeiro pra ele
  whatsapp_secundario: "5518981295957", // SECUNDARIO (admin/funcionario). Se deixar "", o segundo botao some.
  desenvolvedor: {
    nome: "Diogo Carvalho",
    instagram: "https://www.instagram.com/diogocarvalho_16/",
  },
};

// Cliente Supabase global (usa o SDK carregado via CDN no <head>)
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helpers globais
const fmtBRL = (v) => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });

// Escapa HTML pra evitar XSS quando interpolando dados do banco/cliente em innerHTML.
// Use SEMPRE que jogar string vinda de fora dentro de template literal de HTML.
const esc = (v) => {
  if (v === null || v === undefined) return "";
  return String(v)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
};

// Codifica pra usar dentro de atributo onclick='...JSON...'
// O JSON.stringify pode conter ' que quebra o atributo. Codificamos em JSON e escapamos.
const escAttr = (obj) => esc(JSON.stringify(obj));
