from io import BytesIO
import time
from PIL import Image
from app.extensions import db
from app.models import Admin


def login(client, email="admin@example.com", password="initial-password"):
    token = client.get("/api/v1/auth/csrf").json["csrf_token"]
    return client.post("/api/v1/auth/login", json=dict(email=email, password=password), headers={"X-CSRF-Token":token})


def test_local_login_logout_csrf(client):
    assert client.get("/api/v1/auth/me").status_code == 401
    assert client.post("/api/v1/auth/login", json={}).status_code == 403
    assert login(client, password="bad").status_code == 401
    response = login(client)
    assert response.status_code == 200
    assert "HttpOnly" in response.headers["Set-Cookie"] and "SameSite=Lax" in response.headers["Set-Cookie"]
    assert client.get("/api/v1/auth/me").json["user"]["email"] == "admin@example.com"
    assert client.post("/api/v1/auth/logout").status_code == 403
    assert client.post("/api/v1/auth/logout", headers={"X-CSRF-Token":response.json["csrf_token"]}).status_code == 200
    assert client.get("/api/v1/auth/me").status_code == 401
    assert client.post("/api/v1/auth/register", json={}).status_code == 404


def test_inactive_and_absolute_expiry(app, client, authenticated):
    client, headers = authenticated
    with client.session_transaction() as session:
        session["issued_at"] = time.time() - 8 * 3600
    assert client.get("/api/v1/auth/me").status_code == 401
    with app.app_context():
        admin = db.session.scalar(db.select(Admin).filter_by(email="admin@example.com"))
        admin.active = False
        db.session.commit()
    assert login(client).status_code == 401


def test_session_rotation(app, client):
    token = client.get("/api/v1/auth/csrf").json["csrf_token"]
    old_cookie = client.get_cookie("linkguard_session").value
    response = client.post("/api/v1/auth/login", json=dict(email="admin@example.com", password="initial-password"), headers={"X-CSRF-Token":token})
    assert response.status_code == 200
    assert old_cookie != client.get_cookie("linkguard_session").value
    other = app.test_client()
    other.set_cookie("linkguard_session", old_cookie)
    assert other.get("/api/v1/auth/me").status_code == 401


def test_profile_password_and_other_session(app, authenticated):
    client, headers = authenticated
    other = app.test_client()
    assert login(other).status_code == 200
    assert client.patch("/api/v1/profile", json={"name":" "}, headers=headers).status_code == 400
    response = client.patch("/api/v1/profile", json={"name":"New Name","email":"evil@example.com"}, headers=headers)
    assert response.json["user"]["name"] == "New Name"
    assert response.json["user"]["email"] == "admin@example.com"
    assert client.post("/api/v1/profile/password", json={"old_password":"bad","new_password":"new-good-password"}, headers=headers).status_code == 400
    assert client.post("/api/v1/profile/password", json={"old_password":"initial-password","new_password":"tiny"}, headers=headers).status_code == 400
    assert client.post("/api/v1/profile/password", json={"old_password":"initial-password","new_password":"new-good-password"}, headers=headers).status_code == 200
    assert other.get("/api/v1/auth/me").status_code == 401
    assert client.get("/api/v1/auth/me").status_code == 200
    assert login(other, password="new-good-password").status_code == 200


def test_avatar_validation_and_reencoding(authenticated):
    client, headers = authenticated
    assert client.put("/api/v1/profile/avatar", data={"file":(BytesIO(b"not image"),"x.png")}, headers=headers).status_code == 400
    assert client.put("/api/v1/profile/avatar", data={"file":(BytesIO(b"x"*(2*1024*1024+1)),"x.png")}, headers=headers).status_code == 413
    raw = BytesIO()
    Image.new("RGB", (1024, 600), "blue").save(raw, format="PNG")
    response = client.put("/api/v1/profile/avatar", data={"file":(BytesIO(raw.getvalue()),"x.png")}, headers=headers)
    assert response.status_code == 200
    result = client.get("/api/v1/profile/avatar")
    assert result.mimetype == "image/webp"
    with Image.open(BytesIO(result.data)) as image:
        assert image.width <= 512 and image.height <= 512
        assert not image.getexif()


def test_admin_google_routes_are_absent_even_with_credentials(app, client):
    app.config.update(GOOGLE_CLIENT_ID="configured-client", GOOGLE_CLIENT_SECRET="configured-secret")
    assert "google_enabled" not in client.get("/api/v1/auth/csrf").json
    for path in ("/auth/google", "/auth/google/callback?code=fake&state=fake"):
        assert client.get("/api/v1" + path).status_code == 404
    assert client.get("/api/v1/auth/me").status_code == 401
    assert login(client, email="google@example.com").status_code == 401


def test_secure_cookie(app, client):
    app.config["SESSION_COOKIE_SECURE"] = True
    assert "Secure" in client.get("/api/v1/auth/csrf").headers["Set-Cookie"]


def test_cli_admin(app):
    runner = app.test_cli_runner()
    assert runner.invoke(args=["create-admin", "--email", "local@example.com", "--name", "Local", "--password", "safe-bootstrap-password"]).exit_code == 0
    assert runner.invoke(args=["create-admin", "--email", "sso@example.com", "--name", "SSO", "--google-only"]).exit_code != 0
    assert runner.invoke(args=["create-admin", "--email", "other@example.com", "--name", "Other", "--allow-google"]).exit_code != 0
    assert runner.invoke(args=["create-admin", "--email", "weak@example.com", "--name", "Weak", "--password", "short"]).exit_code != 0


def test_login_rate_limit(app):
    from app.extensions import limiter
    from app import create_app
    rate_app = create_app({**app.config, "RATELIMIT_ENABLED": True})
    try:
        client = rate_app.test_client()
        token = client.get("/api/v1/auth/csrf").json["csrf_token"]
        for _ in range(10):
            assert client.post("/api/v1/auth/login", json={"email":"admin@example.com","password":"bad"}, headers={"X-CSRF-Token":token}).status_code == 401
        response = client.post("/api/v1/auth/login", json={"email":"admin@example.com","password":"bad"}, headers={"X-CSRF-Token":token})
        assert response.status_code == 429 and response.json["error"]["code"] == "rate_limited"
    finally:
        limiter.enabled = False
