import pytest

from app.extensions import db
from app.models import Dataset, DatasetRow, DatasetState, PredictionReport


PAYLOAD = {"url": "example.test", "type": "False Negative", "category": "Phishing"}


def account(client, email="owner@example.test"):
    response = client.post("/api/v1/mobile/auth/register", json={
        "name": "Tester", "email": email, "password": "test-password-2026"})
    assert response.status_code == 201
    return response.json["user"]["id"], {"Authorization": "Bearer " + response.json["token"]}


@pytest.mark.parametrize("email", [123, True, [], ["a"], {}, {"a": 1}, None])
def test_registration_rejects_non_string_email(client, email):
    response = client.post("/api/v1/mobile/auth/register", json={
        "name": "Tester", "email": email, "password": "test-password-2026"})
    assert response.status_code == 400
    assert response.json["error"]["code"] == "invalid_email"


def test_owned_reports_ignore_spoofed_identity_and_isolate_users(app, authenticated):
    client, admin_headers = authenticated
    owner_id, owner = account(client)
    other_id, other = account(client, "other@example.test")
    created = client.post("/api/v1/mobile/reports", headers=owner, json={
        **PAYLOAD, "reporter_id": other_id, "reporter_email": "fake@example.test"})
    assert created.status_code == 201
    report_id = created.json["report"]["id"]
    assert "admin_notes" not in created.json["report"]
    with app.app_context():
        report = db.session.get(PredictionReport, report_id)
        assert report.reporter_id == owner_id
        assert report.reporter_email == "owner@example.test"
    assert client.get("/api/v1/mobile/reports", headers=owner).json["row_count"] == 1
    assert client.get("/api/v1/mobile/reports", headers=other).json["items"] == []
    assert client.get(f"/api/v1/mobile/reports/{report_id}", headers=other).status_code == 404
    assert client.get(f"/api/v1/mobile/reports/{report_id}", headers=owner).status_code == 200
    assert client.patch(f"/api/v1/reports/{report_id}", headers=admin_headers,
                        json={"status": "review", "admin_notes": "Internal"}).status_code == 200
    detail = client.get(f"/api/v1/mobile/reports/{report_id}", headers=owner).json["report"]
    assert detail["status"] == "review"
    assert "admin_notes" not in detail


def test_legacy_reports_cannot_be_claimed_by_email(app, client):
    owner_id, owner = account(client)
    response = client.post("/api/v1/reports/submit", json={
        **PAYLOAD, "reporter_id": owner_id, "reporter_email": "owner@example.test"})
    assert response.status_code == 201
    assert response.json["report"]["reporter_id"] is None
    assert client.get("/api/v1/mobile/reports", headers=owner).json["items"] == []


@pytest.mark.parametrize("method,path", [("post", "/reports"), ("get", "/reports"), ("get", "/reports/1")])
def test_mobile_reports_require_bearer_even_with_admin_cookie(authenticated, method, path):
    client, _ = authenticated
    response = getattr(client, method)("/api/v1/mobile" + path)
    assert response.status_code == 401


def test_revoked_token_cannot_submit_reports(client):
    _, headers = account(client)
    assert client.post("/api/v1/mobile/auth/logout", headers=headers).status_code == 200
    assert client.post("/api/v1/mobile/reports", headers=headers, json=PAYLOAD).status_code == 401


def test_mobile_report_validation_and_cors(app, client):
    _, headers = account(client)
    app.config["MOBILE_CORS_ORIGINS"] = ["http://localhost:8080"]
    response = client.post("/api/v1/mobile/reports", headers={**headers, "Origin": "http://localhost:8080"},
                           json={**PAYLOAD, "notes": "x" * 2001})
    assert response.status_code == 400
    assert response.headers["Access-Control-Allow-Origin"] == "http://localhost:8080"
    for query in ("page=0", "page=bad", "page_size=3"):
        assert client.get("/api/v1/mobile/reports?" + query, headers=headers).status_code == 400


def seed(app, columns=("url", "type")):
    with app.app_context():
        db.session.add(Dataset(id="priority2", filename="test.csv", columns=list(columns), row_count=1))
        db.session.flush()
        db.session.add(DatasetRow(dataset_id="priority2", row_number=1, values=[
            "seed.test" if col.strip().lower() == "url" else "phishing" for col in columns]))
        state = db.session.get(DatasetState, 1) or DatasetState(id=1)
        state.active_id = "priority2"
        db.session.add(state)
        db.session.commit()


def test_completed_only_via_sync_and_synced_fields_are_immutable(app, authenticated):
    client, headers = authenticated
    seed(app)
    report_id = client.post("/api/v1/reports/submit", json=PAYLOAD).json["report"]["id"]
    url = f"/api/v1/reports/{report_id}"
    response = client.patch(url, headers=headers, json={"status": "completed"})
    assert response.status_code == 409
    assert response.json["error"]["code"] == "sync_required"
    assert client.post(url + "/sync-dataset", headers=headers).status_code == 200
    for payload in ({"status": "rejected"}, {"reported_category": "Malware"}):
        response = client.patch(url, headers=headers, json={**payload, "admin_notes": "must not save"})
        assert response.status_code == 409
        assert response.json["error"]["code"] == "report_synced"
    response = client.patch(url, headers=headers, json={
        "status": "completed", "reported_category": "phishing", "admin_notes": "Verified"})
    assert response.status_code == 200
    assert response.json["report"]["admin_notes"] == "Verified"
    assert response.json["report"]["status"] == "completed"
    with app.app_context():
        assert db.session.get(DatasetRow, ("priority2", 2)).values == [PAYLOAD["url"], "phishing"]


def test_rejected_report_must_be_reopened_before_sync(app, authenticated):
    client, headers = authenticated
    seed(app)
    report_id = client.post("/api/v1/reports/submit", json=PAYLOAD).json["report"]["id"]
    url = f"/api/v1/reports/{report_id}"
    assert client.patch(url, headers=headers, json={"status": "rejected"}).status_code == 200
    assert client.post(url + "/sync-dataset", headers=headers).json["error"]["code"] == "report_rejected"
    assert client.patch(url, headers=headers, json={"status": "review"}).status_code == 200
    assert client.post(url + "/sync-dataset", headers=headers).status_code == 200


@pytest.mark.parametrize("status", [[], {}, 123, True])
def test_invalid_status_type_returns_400(authenticated, status):
    client, headers = authenticated
    report_id = client.post("/api/v1/reports/submit", json=PAYLOAD).json["report"]["id"]
    assert client.patch(f"/api/v1/reports/{report_id}", headers=headers,
                        json={"status": status}).status_code == 400


@pytest.mark.parametrize("columns", [
    ("url", "source"), ("url", "type", "label"), ("url", "url", "label"),
    ("url_length", "type"), ("url", "content_type"),
])
def test_sync_rejects_missing_or_ambiguous_headers(app, authenticated, columns):
    client, headers = authenticated
    seed(app, columns)
    report_id = client.post("/api/v1/reports/submit", json=PAYLOAD).json["report"]["id"]
    response = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert response.status_code == 409
    assert response.json["error"]["code"] == "unsupported_dataset"
    with app.app_context():
        assert db.session.get(Dataset, "priority2").row_count == 1
        assert not db.session.get(PredictionReport, report_id).dataset_synced


def test_sync_accepts_reordered_trimmed_headers(app, authenticated):
    client, headers = authenticated
    seed(app, (" TYPE ", " URL "))
    report_id = client.post("/api/v1/reports/submit", json=PAYLOAD).json["report"]["id"]
    response = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert response.status_code == 200
    with app.app_context():
        assert db.session.get(DatasetRow, ("priority2", 2)).values == ["phishing", "example.test"]
