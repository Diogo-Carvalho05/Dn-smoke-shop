from http.server import BaseHTTPRequestHandler
import json, os, sys
import bcrypt
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib.supabase_client import get_client
from _lib.auth_guard import gerar_token

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("content-length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        email = (body.get("email") or "").strip().lower()
        senha = body.get("senha") or ""

        sb = get_client()
        res = sb.table("admins").select("*").eq("email", email).limit(1).execute()
        admin = res.data[0] if res.data else None

        if not admin or not bcrypt.checkpw(senha.encode(), admin["senha_hash"].encode()):
            self._json(401, {"erro": "credenciais invalidas"})
            return

        token = gerar_token(admin["id"], admin["email"])
        self._json(200, {"token": token, "email": admin["email"]})

    def _json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
