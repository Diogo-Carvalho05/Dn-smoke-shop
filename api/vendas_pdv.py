from http.server import BaseHTTPRequestHandler
import json
from _lib.supabase_client import get_client
from _lib.auth_guard import verificar_token

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        claims = verificar_token(self.headers.get("Authorization"))
        if not claims:
            self._json(401, {"erro": "nao autorizado"}); return

        body = self._body()
        sb = get_client()
        total = sum(i["preco"] * i["quantidade"] for i in body["itens"])

        # PDV ja baixa estoque imediatamente
        for item in body["itens"]:
            prod = sb.table("produtos").select("estoque").eq("id", item["produto_id"]).single().execute().data
            if prod:
                sb.table("produtos").update(
                    {"estoque": max(0, prod["estoque"] - item["quantidade"])}
                ).eq("id", item["produto_id"]).execute()

        res = sb.table("vendas_pdv").insert({
            "itens": body["itens"],
            "total": total,
            "forma_pagamento": body["forma_pagamento"],
            "admin_id": claims["sub"],
        }).execute()
        self._json(201, res.data[0])

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
