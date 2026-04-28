from http.server import BaseHTTPRequestHandler
import json, os, sys
from urllib.parse import urlparse, parse_qs
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib.supabase_client import get_client
from _lib.auth_guard import verificar_token

class handler(BaseHTTPRequestHandler):
    # Cliente cria pedido (publico)
    def do_POST(self):
        body = self._body()
        sb = get_client()
        total = sum(i["preco"] * i["quantidade"] for i in body["itens"])
        res = sb.table("pedidos").insert({
            "cliente_nome": body["cliente_nome"],
            "cliente_telefone": body["cliente_telefone"],
            "endereco": body["endereco"],
            "itens": body["itens"],
            "total": total,
            "forma_pagamento": body["forma_pagamento"],
            "troco_para": body.get("troco_para"),
            "status": "pendente",
        }).execute()
        self._json(201, res.data[0])

    # Admin lista pedidos
    def do_GET(self):
        if not self._auth():
            return
        qs = parse_qs(urlparse(self.path).query)
        status = qs.get("status", [None])[0]
        sb = get_client()
        q = sb.table("pedidos").select("*").order("criado_em", desc=True)
        if status:
            q = q.eq("status", status)
        self._json(200, q.execute().data)

    # Admin atualiza status (PATCH via PUT) - confirma/entrega/cancela e baixa estoque na entrega
    def do_PUT(self):
        if not self._auth():
            return
        body = self._body()
        pedido_id = body["id"]
        novo_status = body["status"]    # confirmado | entregue | cancelado
        sb = get_client()

        atual = sb.table("pedidos").select("*").eq("id", pedido_id).single().execute().data
        if not atual:
            self._json(404, {"erro": "pedido nao encontrado"}); return

        update = {"status": novo_status}
        if novo_status == "confirmado":
            update["confirmado_em"] = "now()"
        if novo_status == "entregue":
            update["entregue_em"] = "now()"
            # baixa estoque na entrega
            for item in atual["itens"]:
                prod = sb.table("produtos").select("estoque").eq("id", item["produto_id"]).single().execute().data
                if prod:
                    novo_estoque = max(0, prod["estoque"] - item["quantidade"])
                    sb.table("produtos").update({"estoque": novo_estoque}).eq("id", item["produto_id"]).execute()

        res = sb.table("pedidos").update(update).eq("id", pedido_id).execute()
        self._json(200, res.data[0] if res.data else {})

    def _auth(self):
        if not verificar_token(self.headers.get("Authorization")):
            self._json(401, {"erro": "nao autorizado"})
            return False
        return True

    def _body(self):
        length = int(self.headers.get("content-length", 0))
        return json.loads(self.rfile.read(length) or b"{}")

    def _json(self, status, payload):
        body = json.dumps(payload, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
