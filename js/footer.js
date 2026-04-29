// =====================================================================
// Footer com creditos do desenvolvedor — injetado em todas as paginas.
// =====================================================================
(function () {
  const dev = (window.LOJA && LOJA.desenvolvedor) || {
    nome: "Diogo Carvalho",
    instagram: "https://www.instagram.com/diogocarvalho_16/",
  };
  const ano = new Date().getFullYear();

  // Detecta se o body esta em fundo escuro pra escolher cor do texto
  const bg = getComputedStyle(document.body).backgroundColor;
  const m = bg.match(/\d+/g);
  const escuro = m && (Number(m[0]) + Number(m[1]) + Number(m[2])) / 3 < 100;

  const footer = document.createElement("footer");
  footer.className = "mt-12 py-6 text-center text-xs " +
    (escuro ? "text-gray-400" : "text-gray-500 border-t border-gray-200");
  footer.innerHTML = `
    &copy; ${ano} ${(window.LOJA && LOJA.nome) || "Dn Smoke Shop"} &middot;
    Desenvolvido por
    <a href="${dev.instagram}" target="_blank" rel="noopener"
       class="font-semibold ${escuro ? "text-white" : "text-marca-preto"} hover:underline">${dev.nome}</a>
  `;
  document.body.appendChild(footer);
})();
