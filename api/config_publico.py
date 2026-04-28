from http.server import BaseHTTPRequestHandler
import json, os

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({
            "loja_nome": os.environ.get("LOJA_NOME", "Dn Smoke Shop"),
            "whatsapp": os.environ.get("LOJA_WHATSAPP", ""),
        }).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
