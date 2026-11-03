from werkzeug.security import generate_password_hash

from app.extensions import db
from app.models import MobileUser


def sign_up(client, email="nadia@example.com", password="password-nadia-2026", name="Nadia Putri"):
    return client.post("/api/v1/mobile/auth/register",
                       json={"name": name, "email": email, "password": password})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def fake_google(claims):
    def verify(token, client_ids):
        assert token == "google-id-token"
        return claims
    return verify


def test_register_returns_token_and_session(client):
    response = sign_up(client)
    assert response.status_code == 201
    data = response.get_json()
    assert data["token_type"] == "Bearer" and data["token"]
    assert data["user"]["email"] == "nadia@example.com"
    assert "password_hash" not in data["user"]

    me = client.get("/api/v1/mobile/auth/me", headers=bearer(data["token"]))
    assert me.status_code == 200
    assert me.get_json()["user"]["name"] == "Nadia Putri"

    assert client.post("/api/v1/mobile/auth/logout",
                       headers=bearer(data["token"])).status_code == 200
    assert client.get("/api/v1/mobile/auth/me",
                      headers=bearer(data["token"])).status_code == 401


def test_register_rejects_duplicate_email(client):
    assert sign_up(client).status_code == 201
    assert sign_up(client, name="Nadia Lain").status_code == 409


def test_register_validates_input(client):
    assert client.post("/api/v1/mobile/auth/register",
                       json={"name": "", "email": "nadia@example.com",
                             "password": "password-nadia-2026"}).status_code == 400
    assert client.post("/api/v1/mobile/auth/register",
                       json={"name": "Nadia", "email": "not-an-email",
                             "password": "password-nadia-2026"}).status_code == 400
    assert client.post("/api/v1/mobile/auth/register",
                       json={"name": "Nadia", "email": "nadia@example.com",
                             "password": "short"}).status_code == 400


def test_register_does_not_require_admin_csrf(client):
    # Mobile clients never receive the admin CSRF token.
    assert sign_up(client).status_code == 201


def test_login_with_password(client):
    sign_up(client)
    response = client.post("/api/v1/mobile/auth/login",
                           json={"email": "nadia@example.com",
                                 "password": "password-nadia-2026"})
    assert response.status_code == 200
    assert response.get_json()["user"]["email"] == "nadia@example.com"


def test_login_rejects_wrong_password_and_unknown_email(client):
    sign_up(client)
    assert client.post("/api/v1/mobile/auth/login",
                       json={"email": "nadia@example.com",
                             "password": "wrong-password-2026"}).status_code == 401
    assert client.post("/api/v1/mobile/auth/login",
                       json={"email": "missing@example.com",
                             "password": "password-nadia-2026"}).status_code == 401


def test_login_rejects_inactive_user(app, client):
    with app.app_context():
        db.session.add(MobileUser(email="off@example.com", name="Off", active=False,
                                  password_hash=generate_password_hash("password-off-2026",
                                                                       method="scrypt")))
        db.session.commit()
    response = client.post("/api/v1/mobile/auth/login",
                           json={"email": "off@example.com", "password": "password-off-2026"})
    assert response.status_code == 401


def test_mobile_token_cannot_reach_admin_endpoints(client):
    token = sign_up(client).get_json()["token"]
    response = client.get("/api/v1/users?kind=mobile", headers=bearer(token))
    assert response.status_code == 401
    assert response.get_json()["error"]["code"] == "unauthorized"


def test_google_rejected_when_not_configured(app, client):
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = []
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 503


def test_google_registers_new_mobile_user(app, client, monkeypatch):
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token",
                        fake_google({"sub": "google-sub-1", "email": "nadia@gmail.com",
                                     "name": "Nadia Putri", "email_verified": True}))
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 200
    user = response.get_json()["user"]
    assert user["email"] == "nadia@gmail.com"
    assert user["has_password"] is False
    with app.app_context():
        stored = db.session.scalar(db.select(MobileUser).filter_by(email="nadia@gmail.com"))
        assert stored.google_sub == "google-sub-1"


def test_google_login_reuses_existing_google_account(app, client, monkeypatch):
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token",
                        fake_google({"sub": "google-sub-1", "email": "nadia@gmail.com",
                                     "name": "Nadia Putri", "email_verified": True}))
    first = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    second = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert first.status_code == 200 and second.status_code == 200
    assert first.get_json()["user"]["id"] == second.get_json()["user"]["id"]


def test_google_links_existing_password_account(app, client, monkeypatch):
    sign_up(client, email="nadia@example.com")
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token",
                        fake_google({"sub": "google-sub-2", "email": "nadia@example.com",
                                     "name": "Nadia", "email_verified": True}))
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 200
    with app.app_context():
        stored = db.session.scalar(db.select(MobileUser).filter_by(email="nadia@example.com"))
        assert stored.google_sub == "google-sub-2"


def test_google_conflict_when_email_bound_to_other_subject(app, client, monkeypatch):
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    with app.app_context():
        db.session.add(MobileUser(email="nadia@example.com", name="Nadia",
                                  google_sub="google-sub-a", active=True))
        db.session.commit()
    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token",
                        fake_google({"sub": "google-sub-b", "email": "nadia@example.com",
                                     "name": "Nadia", "email_verified": True}))
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 409


def test_google_rejects_inactive_account(app, client, monkeypatch):
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    with app.app_context():
        db.session.add(MobileUser(email="off@example.com", name="Off",
                                  google_sub="google-sub-off", active=False))
        db.session.commit()
    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token",
                        fake_google({"sub": "google-sub-off", "email": "off@example.com",
                                     "name": "Off", "email_verified": True}))
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 403


def test_google_propagates_verification_failure(app, client, monkeypatch):
    from app.services.google_tokens import GoogleTokenError

    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]

    def fail(token, client_ids):
        raise GoogleTokenError("Token Google tidak valid.")

    monkeypatch.setattr("app.routes.mobile_auth.verify_google_id_token", fail)
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-id-token"})
    assert response.status_code == 401
    assert response.get_json()["error"]["code"] == "invalid_google_token"


def test_admin_password_reset_revokes_mobile_token(authenticated, app, client):
    token = sign_up(client).get_json()["token"]
    with app.app_context():
        user_id = db.session.scalar(db.select(MobileUser.id).filter_by(email="nadia@example.com"))
    admin, headers = authenticated
    response = admin.post(f"/api/v1/users/mobile/{user_id}/password",
                          json={"password": "password-baru-2026"}, headers=headers)
    assert response.status_code == 200
    assert client.get("/api/v1/mobile/auth/me", headers=bearer(token)).status_code == 401
