from concurrent.futures import ThreadPoolExecutor
from werkzeug.security import check_password_hash, generate_password_hash
from app.extensions import db
from app.models import Admin, MobileUser

BASE = "/api/v1/users"
PASSWORD = "new-account-password"


def login(client, email="admin@example.com", password="initial-password"):
    token = client.get("/api/v1/auth/csrf").json["csrf_token"]
    response = client.post("/api/v1/auth/login", json=dict(email=email, password=password), headers={"X-CSRF-Token": token})
    assert response.status_code == 200
    return {"X-CSRF-Token": response.json["csrf_token"]}


def test_access_and_no_registration(client, authenticated):
    signed, headers = authenticated
    anonymous = signed.application.test_client()
    assert anonymous.get(BASE).status_code == 401
    assert signed.post(BASE + "/admin", json={}).status_code == 403
    assert anonymous.get("/api/v1/auth/register").status_code == 404
    assert signed.get(BASE + "?kind=unknown").status_code == 400
    assert signed.get(BASE + "?page_size=0").status_code == 400


def test_create_both_kinds_and_isolation(app, authenticated):
    client, headers = authenticated
    for kind in ("admin", "mobile"):
        response = client.post(BASE + "/" + kind, headers=headers, json=dict(name=" New User ", email=" SAME@example.com ", password=PASSWORD))
        assert response.status_code == 201
        user = response.json["user"]
        assert user["name"] == "New User" and user["email"] == "same@example.com"
        assert user["has_password"] and "password_hash" not in user and "google_sub" not in user
        assert client.post(BASE + "/" + kind, headers=headers, json=dict(name="Duplicate", email="same@example.com", password=PASSWORD)).status_code == 409
    with app.app_context():
        mobile = db.session.scalar(db.select(MobileUser))
        assert check_password_hash(mobile.password_hash, PASSWORD)
    client.post(BASE + "/mobile", headers=headers, json=dict(name="Mobile only", email="mobile@example.com", password=PASSWORD))
    other = app.test_client()
    token = other.get("/api/v1/auth/csrf").json["csrf_token"]
    assert other.post("/api/v1/auth/login", headers={"X-CSRF-Token":token}, json=dict(email="mobile@example.com", password=PASSWORD)).status_code == 401


def test_validation_and_password_only_admin(authenticated):
    client, headers = authenticated
    for payload in (dict(name="",email="a@example.com",password=PASSWORD),dict(name="A",email="bad",password=PASSWORD),dict(name="A",email="a@example.com",password="short"),dict(name="A",email="a@example.com"),dict(name="Google",email="new-google@example.com",google_allowed=True)):
        assert client.post(BASE + "/admin",headers=headers,json=payload).status_code == 400
    assert client.patch(BASE + "/admin/1",headers=headers,json=dict(google_allowed=True)).status_code == 400
    # Historical passwordless accounts need a password before activation.
    assert client.patch(BASE + "/admin/2",headers=headers,json=dict(active=True)).status_code == 409
    assert client.post(BASE + "/admin/2/password",headers=headers,json=dict(password=PASSWORD)).status_code == 200
    assert client.patch(BASE + "/admin/2",headers=headers,json=dict(active=True)).status_code == 200
    listed = client.get(BASE).json["items"]
    assert all("google_allowed" not in user for user in listed)


def test_self_and_profile_guards(authenticated):
    client, headers = authenticated
    assert client.patch(BASE + "/admin/1",headers=headers,json=dict(active=False)).status_code == 409
    assert client.post(BASE + "/admin/1/password",headers=headers,json=dict(password=PASSWORD)).status_code == 409
    assert client.patch(BASE + "/admin/1",headers=headers,json=dict(email="changed@example.com")).status_code == 400
    assert client.patch(BASE + "/admin/1",headers=headers,json=dict(name=" Renamed ")).json["user"]["name"] == "Renamed"
    assert client.get("/api/v1/auth/me").json["user"]["name"] == "Renamed"


def test_reset_status_and_session_revocation(app, authenticated):
    client, headers = authenticated
    response = client.post(BASE + "/admin",headers=headers,json=dict(name="Other",email="other@example.com",password=PASSWORD))
    uid = response.json["user"]["id"]
    other = app.test_client()
    login(other,"other@example.com",PASSWORD)
    assert client.post(f"{BASE}/admin/{uid}/password",headers=headers,json=dict(password="replacement-password")).status_code == 200
    assert other.get("/api/v1/auth/me").status_code == 401
    login(other,"other@example.com","replacement-password")
    assert client.patch(f"{BASE}/admin/{uid}",headers=headers,json=dict(active=False)).status_code == 200
    assert other.get("/api/v1/auth/me").status_code == 401
    assert client.patch(f"{BASE}/admin/{uid}",headers=headers,json=dict(active=True)).status_code == 200
    login(other,"other@example.com","replacement-password")


def test_mobile_updates_and_pagination(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        db.session.add_all([MobileUser(name=f"Mobile {i}",email=f"mobile{i}@example.com",password_hash="unused-fixture-hash") for i in range(63)])
        db.session.commit()
    for size, last_count, pages in ((25,13,3),(50,13,2),(100,63,1)):
        response = client.get(f"{BASE}?kind=mobile&page_size={size}&page={pages}").json
        assert response["row_count"] == 63 and response["page_count"] == pages
        assert len(response["items"]) == last_count
    assert client.patch(BASE + "/mobile/1",headers=headers,json=dict(name=" Updated ",active=False)).json["user"]["name"] == "Updated"
    assert client.post(BASE + "/mobile/1/password",headers=headers,json=dict(password=PASSWORD)).status_code == 200
    with app.app_context():
        user = db.session.get(MobileUser,1)
        assert not user.active and check_password_hash(user.password_hash,PASSWORD)
    assert client.patch(BASE + "/mobile/999",headers=headers,json=dict(active=False)).status_code == 404


def test_concurrent_admin_deactivation_preserves_access(app, authenticated):
    client, headers = authenticated
    client.patch(BASE + "/admin/2",headers=headers,json=dict(active=False))
    created = client.post(BASE + "/admin",headers=headers,json=dict(name="Other",email="other@example.com",password=PASSWORD))
    uid = created.json["user"]["id"]
    other = app.test_client()
    other_headers = login(other,"other@example.com",PASSWORD)
    with ThreadPoolExecutor(max_workers=2) as pool:
        a = pool.submit(client.patch,f"{BASE}/admin/{uid}",headers=headers,json=dict(active=False))
        b = pool.submit(other.patch,BASE + "/admin/1",headers=other_headers,json=dict(active=False))
        assert sorted([a.result().status_code,b.result().status_code]) == [200,401]
    with app.app_context():
        assert db.session.scalar(db.select(db.func.count()).select_from(Admin).where(Admin.active.is_(True))) == 1
