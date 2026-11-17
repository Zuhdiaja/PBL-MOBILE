"""Admin read-only view of the scans submitted from the mobile app."""
from uuid import uuid4

from app.extensions import db
from app.models import MobileUser, Scan, now


def _user(app, email, name="Pengguna", active=True):
    with app.app_context():
        user = MobileUser(
            name=name,
            email=email,
            active=active,
            password_hash="x",
        )
        db.session.add(user)
        db.session.commit()
        return user.id


def _scan(app, user_id, category, url="https://contoh.test", offset=0):
    scan_id = f"scan-{uuid4().hex[:24]}"
    with app.app_context():
        db.session.add(
            Scan(
                id=scan_id,
                mobile_user_id=user_id,
                url=url,
                model_input=url,
                category=category,
                score=1.0 + offset,
                score_kind="margin",
                created_at=now(),
            )
        )
        db.session.commit()
    return scan_id


def test_scans_require_an_admin_session(client):
    assert client.get("/api/v1/scans").status_code == 401
    assert client.get("/api/v1/scans/summary").status_code == 401


def test_scans_list_every_user_with_the_owner(app, authenticated):
    client, headers = authenticated
    first = _user(app, "satu@example.test", name="Satu")
    second = _user(app, "dua@example.test", name="Dua")
    _scan(app, first, "phishing", "https://satu.test")
    _scan(app, second, "benign", "https://dua.test")

    response = client.get("/api/v1/scans", headers=headers)

    assert response.status_code == 200
    body = response.json
    assert body["row_count"] == 2
    owners = {item["user"]["email"] for item in body["items"]}
    assert owners == {"satu@example.test", "dua@example.test"}
    assert {item["url"] for item in body["items"]} == {"https://satu.test", "https://dua.test"}
    # The owner block carries enough to identify the account in the table.
    assert all(item["user"]["name"] for item in body["items"])


def test_scans_filter_by_category(app, authenticated):
    client, headers = authenticated
    owner = _user(app, "filter@example.test")
    _scan(app, owner, "phishing", offset=0)
    _scan(app, owner, "benign", offset=1)
    _scan(app, owner, "legitimate", offset=2)

    response = client.get("/api/v1/scans?category=legitimate", headers=headers)

    assert response.status_code == 200
    assert response.json["row_count"] == 1
    assert response.json["items"][0]["category"] == "legitimate"


def test_scans_accept_all_as_no_filter(app, authenticated):
    client, headers = authenticated
    owner = _user(app, "all@example.test")
    _scan(app, owner, "phishing", offset=0)
    _scan(app, owner, "spam", offset=1)

    response = client.get("/api/v1/scans?category=all", headers=headers)

    assert response.status_code == 200
    assert response.json["row_count"] == 2


def test_scans_search_matches_url_and_owner(app, authenticated):
    client, headers = authenticated
    owner = _user(app, "cari@example.test", name="Nadia Putri")
    _scan(app, owner, "phishing", "https://bank-palsu.test/login", offset=0)
    _scan(app, owner, "benign", "https://aman.test", offset=1)

    by_url = client.get("/api/v1/scans?search=bank-palsu", headers=headers)
    assert by_url.status_code == 200
    assert by_url.json["row_count"] == 1

    by_owner = client.get("/api/v1/scans?search=nadia", headers=headers)
    assert by_owner.json["row_count"] == 2


def test_scans_reject_invalid_pagination(authenticated):
    client, headers = authenticated

    assert client.get("/api/v1/scans?page=abc", headers=headers).status_code == 400
    assert client.get("/api/v1/scans?page_size=7", headers=headers).status_code == 400


def test_scans_page_is_clamped_to_the_last_page(app, authenticated):
    client, headers = authenticated
    owner = _user(app, "clamp@example.test")
    _scan(app, owner, "benign", offset=0)

    response = client.get("/api/v1/scans?page=99", headers=headers)

    assert response.status_code == 200
    assert response.json["page"] == 1
    assert response.json["page_count"] == 1


def test_scans_summary_counts_categories_and_users(app, authenticated):
    client, headers = authenticated
    first = _user(app, "sum1@example.test")
    second = _user(app, "sum2@example.test")
    _scan(app, first, "benign", offset=0)
    _scan(app, first, "legitimate", offset=1)
    _scan(app, second, "phishing", offset=2)
    _scan(app, second, "phishing", offset=3)

    response = client.get("/api/v1/scans/summary", headers=headers)

    assert response.status_code == 200
    body = response.json
    assert body["total"] == 4
    # legitimate counts as safe alongside benign, but stays a separate key.
    assert body["safe"] == 2
    assert body["unsafe"] == 2
    assert body["users"] == 2
    assert body["by_category"]["phishing"] == 2
    assert body["by_category"]["legitimate"] == 1


def test_scans_summary_is_empty_without_scans(client, authenticated):
    client, headers = authenticated

    response = client.get("/api/v1/scans/summary", headers=headers)

    assert response.status_code == 200
    assert response.json["total"] == 0
    assert response.json["users"] == 0
    assert response.json["by_category"] == {}
