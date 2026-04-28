import os
import jwt
from datetime import datetime, timedelta, timezone

ALG = "HS256"

def gerar_token(admin_id: str, email: str) -> str:
    payload = {
        "sub": admin_id,
        "email": email,
        "exp": datetime.now(timezone.utc) + timedelta(hours=12),
    }
    return jwt.encode(payload, os.environ["JWT_SECRET"], algorithm=ALG)

def verificar_token(authorization_header: str | None) -> dict | None:
    if not authorization_header or not authorization_header.startswith("Bearer "):
        return None
    token = authorization_header.split(" ", 1)[1]
    try:
        return jwt.decode(token, os.environ["JWT_SECRET"], algorithms=[ALG])
    except jwt.PyJWTError:
        return None
