import time

import pytest
from joserfc import jwt
from joserfc.jwk import RSAKey

from app.services import google_tokens
from app.services.google_tokens import GoogleTokenError, verify_google_id_token

CLIENT_ID = "mobile-client"


@pytest.fixture()
def signing_key():
    return RSAKey.generate_key(2048, private=True, parameters={"kid": "test-kid"})


@pytest.fixture()
def certificates(signing_key, monkeypatch):
    payload = {"keys": [signing_key.as_dict(private=False)]}
    monkeypatch.setattr(google_tokens, "_certificates",
                        {"payload": payload, "expires_at": time.time() + 3600})
    return payload


def make_token(signing_key, **overrides):
    claims = {"iss": "https://accounts.google.com", "aud": CLIENT_ID, "sub": "google-sub",
              "email": "nadia@gmail.com", "email_verified": True,
              "exp": int(time.time()) + 600}
    claims.update(overrides)
    return jwt.encode({"alg": "RS256", "kid": "test-kid"}, claims, signing_key)


def no_fetch(*args, **kwargs):
    pytest.fail("certificates should be cached")


def test_valid_token_returns_claims(certificates, signing_key):
    claims = verify_google_id_token(make_token(signing_key), [CLIENT_ID], http_get=no_fetch)
    assert claims["sub"] == "google-sub"
    assert claims["email"] == "nadia@gmail.com"


def test_accepts_audience_list(certificates, signing_key):
    token = make_token(signing_key, aud=["other-client", CLIENT_ID])
    assert verify_google_id_token(token, [CLIENT_ID], http_get=no_fetch)["sub"] == "google-sub"


@pytest.mark.parametrize("overrides", [
    {"aud": "another-app"},
    {"iss": "https://evil.example.com"},
    {"exp": int(time.time()) - 10},
    {"email_verified": False},
    {"email": ""},
    {"sub": ""},
])
def test_rejects_untrusted_claims(certificates, signing_key, overrides):
    with pytest.raises(GoogleTokenError):
        verify_google_id_token(make_token(signing_key, **overrides), [CLIENT_ID], http_get=no_fetch)


def test_rejects_token_without_known_key(certificates, signing_key):
    unknown = RSAKey.generate_key(2048, private=True, parameters={"kid": "unknown-kid"})
    with pytest.raises(GoogleTokenError):
        verify_google_id_token(make_token(unknown), [CLIENT_ID], http_get=no_fetch)


def test_rejects_malformed_and_oversized_tokens(certificates):
    with pytest.raises(GoogleTokenError):
        verify_google_id_token("not-a-jwt", [CLIENT_ID], http_get=no_fetch)
    with pytest.raises(GoogleTokenError):
        verify_google_id_token("a" * 5000, [CLIENT_ID], http_get=no_fetch)


def test_requires_configured_client_ids(certificates, signing_key):
    with pytest.raises(GoogleTokenError):
        verify_google_id_token(make_token(signing_key), [], http_get=no_fetch)
