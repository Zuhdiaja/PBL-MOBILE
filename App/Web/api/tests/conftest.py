import os
from pathlib import Path
import pytest
from redis import Redis
from werkzeug.security import generate_password_hash
from app import create_app
from app.extensions import db
from app.models import Admin
from app.routes import reports as reports_routes


@pytest.fixture()
def app(tmp_path):
    url = os.environ.get("TEST_DATABASE_URL")
    if not url or not url.endswith("/linkguard_test"):
        pytest.fail("TEST_DATABASE_URL must point to the dedicated PostgreSQL linkguard_test database")
    redis_url = os.environ.get("TEST_REDIS_URL", "redis://localhost:6379/15")
    if not redis_url.endswith("/15"):
        pytest.fail("Tests require dedicated Redis database 15")
    redis = Redis.from_url(redis_url)
    redis.flushdb()
    # The label cache is process-wide; a fresh database must not reuse old spellings.
    reports_routes._LABEL_CACHE.clear()
    application = create_app(dict(TESTING=True, SQLALCHEMY_DATABASE_URI=url,
        SESSION_REDIS=redis, RATELIMIT_STORAGE_URI=redis_url, RATELIMIT_ENABLED=False,
        PRIVATE_STORAGE=str(tmp_path), GOOGLE_CLIENT_ID="test-client", GOOGLE_CLIENT_SECRET="test-secret"))
    with application.app_context():
        db.drop_all()
        db.create_all()
        db.session.add(Admin(email="admin@example.com", name="Admin", google_allowed=True,
            password_hash=generate_password_hash("initial-password", method="scrypt")))
        db.session.add(Admin(email="google@example.com", name="Google Admin", google_allowed=True))
        db.session.commit()
    yield application
    with application.app_context():
        db.session.remove()
        db.drop_all()
    redis.flushdb()


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def authenticated(client):
    token = client.get("/api/v1/auth/csrf").json["csrf_token"]
    response = client.post("/api/v1/auth/login", json={"email":"admin@example.com", "password":"initial-password"}, headers={"X-CSRF-Token":token})
    assert response.status_code == 200
    return client, {"X-CSRF-Token":response.json["csrf_token"]}
