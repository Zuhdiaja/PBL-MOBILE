"""Verification of Google ID tokens for the mobile app.

The mobile client obtains an ID token from Google and sends it to the API. Only
this server decides whether the token is genuine: signature, issuer, audience,
expiry, and verified email are all checked here. Client secrets never reach the
device.
"""
import time
import requests
from joserfc import jwt
from joserfc.errors import JoseError
from joserfc.jwk import KeySet

CERTIFICATES_URL = "https://www.googleapis.com/oauth2/v3/certs"
ISSUERS = ("accounts.google.com", "https://accounts.google.com")
MAX_TOKEN_LENGTH = 4096
DEFAULT_CACHE_SECONDS = 3600

_certificates = {"payload": None, "expires_at": 0.0}


class GoogleTokenError(Exception):
    """A Google credential that the API refuses to trust."""


def _certificates_from_google(http_get):
    payload = http_get(CERTIFICATES_URL, timeout=5)
    payload.raise_for_status()
    data = payload.json()
    if not isinstance(data, dict) or not isinstance(data.get("keys"), list):
        raise GoogleTokenError("Sertifikat Google tidak dapat dibaca.")
    max_age = DEFAULT_CACHE_SECONDS
    cache_control = payload.headers.get("Cache-Control", "")
    for directive in cache_control.split(","):
        name, _, value = directive.strip().partition("=")
        if name == "max-age" and value.isdigit():
            max_age = min(int(value), DEFAULT_CACHE_SECONDS)
    return data, time.time() + max_age


def _key_set(http_get):
    if _certificates["payload"] is None or time.time() >= _certificates["expires_at"]:
        data, expires_at = _certificates_from_google(http_get)
        _certificates["payload"] = data
        _certificates["expires_at"] = expires_at
    try:
        return KeySet.import_key_set(_certificates["payload"])
    except (ValueError, KeyError, TypeError) as exc:
        _certificates["payload"] = None
        raise GoogleTokenError("Sertifikat Google tidak valid.") from exc


def verify_google_id_token(token, client_ids, http_get=requests.get):
    """Return verified claims, or raise GoogleTokenError."""
    if not isinstance(token, str) or not 0 < len(token) <= MAX_TOKEN_LENGTH:
        raise GoogleTokenError("Token Google tidak valid.")
    if not client_ids:
        raise GoogleTokenError("Login Google belum dikonfigurasi.")
    try:
        claims = jwt.decode(token, _key_set(http_get), algorithms=["RS256"]).claims
    except (JoseError, ValueError, KeyError, TypeError) as exc:
        raise GoogleTokenError("Token Google tidak valid.") from exc

    now = time.time()
    try:
        expires_at = float(claims["exp"])
    except (KeyError, TypeError, ValueError) as exc:
        raise GoogleTokenError("Token Google tidak memiliki masa berlaku.") from exc
    if expires_at <= now:
        raise GoogleTokenError("Token Google sudah kedaluwarsa.")
    if claims.get("iss") not in ISSUERS:
        raise GoogleTokenError("Penerbit token Google tidak dikenali.")
    audience = claims.get("aud")
    audiences = audience if isinstance(audience, list) else [audience]
    if not set(audiences) & set(client_ids):
        raise GoogleTokenError("Token Google bukan untuk aplikasi ini.")
    if "sub" not in claims or not str(claims["sub"]).strip():
        raise GoogleTokenError("Token Google tidak memiliki identitas.")
    if not claims.get("email") or claims.get("email_verified") not in (True, "true"):
        raise GoogleTokenError("Email Google belum terverifikasi.")
    return claims
