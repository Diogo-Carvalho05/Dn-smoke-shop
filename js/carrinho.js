// Carrinho persistido em localStorage
const Carrinho = {
  KEY: "dn_carrinho",
  itens() { return JSON.parse(localStorage.getItem(this.KEY) || "[]"); },
  salvar(itens) { localStorage.setItem(this.KEY, JSON.stringify(itens)); },
  limpar() { localStorage.removeItem(this.KEY); },
  add(produto, qtd = 1) {
    const itens = this.itens();
    const i = itens.findIndex(x => x.produto_id === produto.id);
    if (i >= 0) itens[i].quantidade += qtd;
    else itens.push({
      produto_id: produto.id,
      nome: produto.nome,
      preco: Number(produto.preco),
      quantidade: qtd,
    });
    this.salvar(itens);
  },
  remover(produto_id) {
    this.salvar(this.itens().filter(x => x.produto_id !== produto_id));
  },
  setQtd(produto_id, qtd) {
    const itens = this.itens();
    const i = itens.findIndex(x => x.produto_id === produto_id);
    if (i >= 0) {
      if (qtd <= 0) itens.splice(i, 1);
      else itens[i].quantidade = qtd;
      this.salvar(itens);
    }
  },
  total() { return this.itens().reduce((s, i) => s + i.preco * i.quantidade, 0); },
  qtdTotal() { return this.itens().reduce((s, i) => s + i.quantidade, 0); },
};
