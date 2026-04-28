from http.server import BaseHTTPRequestHandler
import json
from urllib.parse import urlparse, parse_qs
from _lib.supabase_client import get_client
from _lib.auth_guard import verificar_token

class handler(BaseHTTPRequestHandler):
    # Publico: lista produtos ativos para a loja
    def do_GET(self):
        qs = parse_qs(urlparse(self.path).query)
        somente_ativos = qs.get("ativos", ["1"])[0] == "1"
        sb = get_client()
        q = sb.table("produtos").select("*").order("nome")
        if somente_ativos:
            q = q.eq("ativo", True)
        res = q.execute()
        self._json(200, res.data)

    # Admin: criar
    def do_POST(self):
        if not self._auth():
            return
        body = self._body()
        sb = get_client()
        res = sb.table("produtos").insert({
            "nome": body["nome"],
            "descricao": body.get("descricao"),
            "preco": body["preco"],
            "estoque": body.get("estoque", 0),
            "imagem_url": body.get("imagem_url"),
            "ativo": body.get("ativo", True),
        }).execute()
        self._json(201, res.data[0])

    # Admin: editar
    def do_PUT(self):
        if not self._auth():
            return
        body = self._body()
        produto_id = body.pop("id")
        sb = get_client()
        res = sb.table("produtos").update(body).eq("id", produto_id).execute()
        self._json(200, res.data[0] if res.data else {})

    # Admin: deletar (soft = ativo=false)
    def do_DELETE(self):
        if not self._auth():
            return
        qs = parse_qs(urlparse(self.path).query)
        produto_id = qs.get("id", [None])[0]
        sb = get_client()
        sb.table("produtos").update({"ativo": False}).eq("id", produto_id).execute()
        self._json(204, {})

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
