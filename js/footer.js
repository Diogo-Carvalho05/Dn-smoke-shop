(function () {
  const KEY_DARK = "dn_dark";

  // ── 1. CSS do modo escuro ─────────────────────────────────────────────
  const style = document.createElement("style");
  style.textContent = `
    html.dark body                        { background-color:#0f0f0f!important; color:#f1f1f1!important; }
    html.dark .bg-marca-claro             { background-color:#0f0f0f!important; }
    html.dark .card,
    html.dark .bg-marca-branco,
    html.dark .bg-white                   { background-color:#1a1a1a!important; border-color:#2d2d2d!important; }
    html.dark .text-marca-preto           { color:#f1f1f1!important; }
    html.dark .text-gray-500,
    html.dark .text-gray-600              { color:#9ca3af!important; }
    html.dark .text-gray-700              { color:#cbd5e1!important; }
    html.dark .border-gray-200,
    html.dark .border-gray-300            { border-color:#2d2d2d!important; }
    html.dark .bg-gray-100,
    html.dark .bg-gray-200                { background-color:#252525!important; }
    html.dark .bg-gray-50                 { background-color:#1d1d1d!important; }
    html.dark input, html.dark textarea,
    html.dark select                      { background-color:#252525!important; border-color:#3d3d3d!important; color:#f1f1f1!important; }
    html.dark input::placeholder,
    html.dark textarea::placeholder       { color:#6b7280!important; }
    html.dark .btn-outline                { border-color:#555!important; color:#f1f1f1!important; }
    html.dark .btn-outline:hover          { background-color:#f1f1f1!important; color:#0a0a0a!important; }
    html.dark thead                       { background-color:#000!important; }
    html.dark tr                          { border-color:#2d2d2d!important; }
    html.dark tr:hover                    { background-color:#1f1f1f!important; }
    html.dark .overflow-x-auto           { background-color:#1a1a1a!important; }
    html.dark details                     { background-color:#1a1a1a!important; }
    html.dark summary                     { color:#f1f1f1!important; }
    html.dark .text-red-700              { color:#fca5a5!important; }
    html.dark .bg-yellow-200             { background-color:#78350f!important; color:#fde68a!important; }
    html.dark .bg-blue-200               { background-color:#1e3a5f!important; color:#bfdbfe!important; }
    html.dark .bg-purple-200             { background-color:#3b1f5e!important; color:#e9d5ff!important; }
    html.dark .bg-green-200              { background-color:#14532d!important; color:#bbf7d0!important; }
    html.dark .bg-red-200                { background-color:#7f1d1d!important; color:#fecaca!important; }
    html.dark footer                      { border-color:#2d2d2d!important; color:#6b7280!important; }
    html.dark footer a                    { color:#e5e7eb!important; }
    html.dark #badge-carrinho             { background-color:#ffffff!important; color:#0a0a0a!important; }
    html.dark .btn-primary                { background-color:#f1f1f1!important; color:#0a0a0a!important; }
    html.dark .btn-primary:hover          { background-color:#ffffff!important; color:#0a0a0a!important; }
    html.dark .btn-primary:disabled       { background-color:#3d3d3d!important; color:#888!important; }

    /* botao flutuante */
    #dn-dark-btn {
      position:fixed; bottom:72px; right:16px;
      width:42px; height:42px; border-radius:50%;
      border:1px solid rgba(128,128,128,.25);
      background:rgba(255,255,255,.92);
      backdrop-filter:blur(6px);
      font-size:20px; cursor:pointer;
      z-index:8000; display:flex; align-items:center; justify-content:center;
      box-shadow:0 2px 10px rgba(0,0,0,.15);
      transition:transform .2s, background .3s, border-color .3s;
    }
    html.dark #dn-dark-btn {
      background:rgba(30,30,30,.92)!important;
      border-color:rgba(255,255,255,.15)!important;
    }
    #dn-dark-btn:hover { transform:scale(1.12); }
  `;
  document.head.appendChild(style);

  // ── 2. Aplica preferencia salva imediatamente ─────────────────────────
  const salvo = localStorage.getItem(KEY_DARK);
  const prefereDark = salvo !== null
    ? salvo === "1"
    : window.matchMedia("(prefers-color-scheme: dark)").matches;
  if (prefereDark) document.documentElement.classList.add("dark");

  // ── 3. Footer ─────────────────────────────────────────────────────────
  const dev = (window.LOJA && LOJA.desenvolvedor) || {
    nome: "Diogo Carvalho",
    instagram: "https://www.instagram.com/diogocarvalho_16/",
  };
  const ano = new Date().getFullYear();
  const bg  = getComputedStyle(document.body).backgroundColor;
  const m   = bg.match(/\d+/g);
  const escuro = m && (Number(m[0]) + Number(m[1]) + Number(m[2])) / 3 < 100;

  const footer = document.createElement("footer");
  footer.className = "mt-12 py-6 text-center text-xs " +
    (escuro ? "text-gray-400" : "text-gray-500 border-t border-gray-200");
  footer.innerHTML = `
    &copy; ${ano} ${(window.LOJA && LOJA.nome) || "Dn Smoke Shop"} &middot;
    Desenvolvido por
    <a href="${dev.instagram}" target="_blank" rel="noopener"
       class="font-semibold ${escuro ? "text-white" : "text-marca-preto"} hover:underline"
    >${dev.nome}</a>
  `;
  document.body.appendChild(footer);

  // ── 4. Botao lua / sol ────────────────────────────────────────────────
  function setDark(ativo) {
    document.documentElement.classList.toggle("dark", ativo);
    localStorage.setItem(KEY_DARK, ativo ? "1" : "0");
    btn.textContent = ativo ? "☀️" : "🌙";
    btn.title       = ativo ? "Mudar para modo claro" : "Mudar para modo escuro";
  }

  const btn = document.createElement("button");
  btn.id          = "dn-dark-btn";
  btn.textContent = prefereDark ? "☀️" : "🌙";
  btn.title       = prefereDark ? "Mudar para modo claro" : "Mudar para modo escuro";
  btn.setAttribute("aria-label", "Alternar modo escuro");
  btn.onclick     = () => setDark(!document.documentElement.classList.contains("dark"));
  document.body.appendChild(btn);
})();
