from http.server import BaseHTTPRequestHandler
import json, base64, uuid, os
from _lib.supabase_client import get_client
from _lib.auth_guard import verificar_token

BUCKET = "produtos"

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if not verificar_token(self.headers.get("Authorization")):
            self._json(401, {"erro": "nao autorizado"}); return

        length = int(self.headers.get("content-length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        # body: { filename, content_base64, content_type }
        nome = f"{uuid.uuid4()}-{body['filename']}"
        binario = base64.b64decode(body["content_base64"])

        sb = get_client()
        sb.storage.from_(BUCKET).upload(
            path=nome,
            file=binario,
            file_options={"content-type": body.get("content_type", "image/jpeg")}
        )
        url = sb.storage.from_(BUCKET).get_public_url(nome)
        self._json(201, {"url": url})

    def _json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
