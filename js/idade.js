// =====================================================================
// Verificacao de idade (18+) — bloqueia menores de idade na entrada da loja.
// Salva confirmacao em localStorage (so pergunta uma vez por dispositivo).
// =====================================================================
(function () {
  const KEY = "dn_idade_confirmada";
  if (localStorage.getItem(KEY) === "1") return;

  const overlay = document.createElement("div");
  overlay.id = "idade-overlay";
  overlay.style.cssText =
    "position:fixed;inset:0;background:#0a0a0a;color:#fff;z-index:9999;" +
    "display:flex;align-items:center;justify-content:center;padding:1rem;font-family:system-ui,sans-serif;";

  overlay.innerHTML = `
    <div style="max-width:420px;width:100%;text-align:center;">
      <h1 style="font-size:1.5rem;font-weight:bold;margin-bottom:0.5rem;letter-spacing:0.05em;">DN SMOKE SHOP</h1>
      <div style="border:1px solid #fff;padding:1.5rem;border-radius:0.75rem;">
        <p style="font-size:1.1rem;font-weight:600;margin-bottom:0.5rem;">Voce tem 18 anos ou mais?</p>
        <p style="font-size:0.85rem;color:#bbb;margin-bottom:1.25rem;">
          A venda de cigarros eletronicos e produtos de tabaco e proibida para menores de 18 anos.
        </p>
        <div style="display:flex;gap:0.5rem;justify-content:center;">
          <button id="idade-sim" style="background:#fff;color:#0a0a0a;border:0;padding:0.6rem 1.25rem;border-radius:0.5rem;font-weight:600;cursor:pointer;">Sim, tenho 18+</button>
          <button id="idade-nao" style="background:transparent;color:#fff;border:1px solid #fff;padding:0.6rem 1.25rem;border-radius:0.5rem;font-weight:600;cursor:pointer;">Nao</button>
        </div>
      </div>
    </div>`;

  // Bloqueia o body ate decidir
  document.documentElement.style.overflow = "hidden";
  document.body.appendChild(overlay);

  document.getElementById("idade-sim").onclick = () => {
    localStorage.setItem(KEY, "1");
    document.documentElement.style.overflow = "";
    overlay.remove();
  };
  document.getElementById("idade-nao").onclick = () => {
    overlay.innerHTML = `
      <div style="max-width:420px;width:100%;text-align:center;">
        <h1 style="font-size:1.5rem;font-weight:bold;margin-bottom:0.5rem;">Acesso bloqueado</h1>
        <p style="color:#bbb;">Voce precisa ter 18 anos ou mais para acessar este site.</p>
      </div>`;
  };
})();
