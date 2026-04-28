from http.server import BaseHTTPRequestHandler
import json, os, sys
from urllib.parse import urlparse, parse_qs
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib.supabase_client import get_client
from _lib.auth_guard import verificar_token

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if not verificar_token(self.headers.get("Authorization")):
            self._json(401, {"erro": "nao autorizado"}); return

        qs = parse_qs(urlparse(self.path).query)
        de = qs.get("de", [None])[0]            # YYYY-MM-DD
        ate = qs.get("ate", [None])[0]
        origem = qs.get("origem", ["todos"])[0]  # online | pdv | todos

        sb = get_client()
        online = []
        pdv = []

        if origem in ("online", "todos"):
            q = sb.table("pedidos").select("*").eq("status", "entregue")
            if de:  q = q.gte("entregue_em", de)
            if ate: q = q.lte("entregue_em", f"{ate}T23:59:59")
            online = q.execute().data or []

        if origem in ("pdv", "todos"):
            q = sb.table("vendas_pdv").select("*")
            if de:  q = q.gte("criado_em", de)
            if ate: q = q.lte("criado_em", f"{ate}T23:59:59")
            pdv = q.execute().data or []

        total_online = sum(p["total"] for p in online)
        total_pdv = sum(v["total"] for v in pdv)

        self._json(200, {
            "online": {"vendas": online, "total": total_online, "qtd": len(online)},
            "pdv":    {"vendas": pdv,    "total": total_pdv,    "qtd": len(pdv)},
            "geral":  {"total": total_online + total_pdv, "qtd": len(online) + len(pdv)},
        })

    def _json(self, status, payload):
        body = json.dumps(payload, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
