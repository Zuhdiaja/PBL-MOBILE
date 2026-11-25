import csv
import io
from datetime import datetime, timedelta, timezone

from app.extensions import client_address, db
from app.models import Dataset, DatasetRow, DatasetState, MobileDevice, MobileUser, PredictionReport, PushOutbox, Scan


def test_health_rejects_database_without_migration_revision(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 503
    assert response.json["error"]["code"] == "schema_outdated"


def test_proxy_address_requires_the_configured_peer(app, monkeypatch):
    app.config["TRUSTED_PROXY_HOST"] = "web"
    monkeypatch.setattr("app.extensions.getaddrinfo", lambda *_: [(0, 0, 0, "", ("10.12.0.2", 0))])
    for address, expected in [("10.12.0.2", "203.0.113.7"), ("10.12.0.3", "10.12.0.3")]:
        with app.test_request_context(headers={"X-LinkGuard-Client-IP": "203.0.113.7"},
                                      environ_base={"REMOTE_ADDR": address}):
            assert client_address() == expected


def test_csv_export_includes_curated_rows(app, authenticated):
    client, _ = authenticated
    with app.app_context():
        db.session.add(Dataset(id="active", filename="active.csv", columns=["url", "label"], row_count=2))
        db.session.add(DatasetState(id=1, active_id="active"))
        db.session.add_all([
            DatasetRow(dataset_id="active", row_number=1, values=["example.test", "benign"]),
            DatasetRow(dataset_id="active", row_number=2, values=["example.test/corrected?q=a,b", "phishing"]),
        ])
        db.session.commit()
    response = client.get("/api/v1/dataset/export")
    assert response.status_code == 200
    assert list(csv.reader(io.StringIO(response.get_data(as_text=True)))) == [
        ["url", "label"], ["example.test", "benign"], ["example.test/corrected?q=a,b", "phishing"],
    ]


def test_week_aggregation_uses_wib_and_scan_detail_is_owned(app, client, monkeypatch):
    moment = datetime(2026, 11, 23, 18, tzinfo=timezone.utc)
    monkeypatch.setattr("app.routes.mobile_scan.now", lambda: moment)
    auth = client.post("/api/v1/mobile/auth/register", json={
        "email": "weekly@example.test", "name": "Weekly", "password": "weekly-testing-password",
    }).json
    headers = {"Authorization": "Bearer " + auth["token"]}
    with app.app_context():
        user = db.session.scalar(db.select(MobileUser).filter_by(email="weekly@example.test"))
        for i, delta in enumerate([0, 8]):
            db.session.add(Scan(id=f"scan-{i}", mobile_user_id=user.id,
                                url="https://example.test", model_input="example.test",
                                category="benign", score=1, score_kind="margin",
                                created_at=moment - timedelta(days=delta)))
        db.session.commit()
    weekly = client.get("/api/v1/mobile/scans/summary?period=7d", headers=headers).json
    assert weekly["total"] == 1 and len(weekly["weekly"]) == 7
    assert weekly["weekly"][-1] == {"date": "2026-11-24", "count": 1}
    assert client.get("/api/v1/mobile/scans/scan-0", headers=headers).json["scan"]["scan_id"] == "scan-0"
    assert client.get("/api/v1/mobile/scans/scan-0").status_code == 401


def test_push_worker_discards_revoked_device_before_sending(app, monkeypatch):
    import firebase_admin
    from push_worker import deliver_one

    monkeypatch.setattr(firebase_admin, "get_app", lambda: object())
    with app.app_context():
        user = MobileUser(email="push@example.test", name="Push", token_version=2)
        db.session.add(user)
        db.session.flush()
        report = PredictionReport(url="https://example.test", report_type="False Positive",
                                  reported_category="Benign", reporter_id=user.id, status="review")
        db.session.add(report)
        db.session.flush()
        db.session.add(PushOutbox(report_id=report.id, status="review"))
        db.session.add(MobileDevice(installation_id="audit-test", user_id=user.id,
                                    token="test-only", session_key="device-binding"))
        db.session.commit()
        app.config["SESSION_REDIS"].set("device-binding", f"{user.id}:1")
        sent = []
        monkeypatch.setattr("firebase_admin.messaging.send", sent.append)
        deliver_one()
        assert not sent
        assert db.session.scalar(db.select(MobileDevice)) is None


def test_notification_event_changes_only_when_report_status_changes(authenticated):
    client, headers = authenticated
    token = client.post("/api/v1/mobile/auth/register", json={
        "email": "notify@example.test", "name": "Notify", "password": "notify-testing-password",
    }).json["token"]
    mobile = {"Authorization": "Bearer " + token}
    report = client.post("/api/v1/mobile/reports", headers=mobile, json={
        "url": "https://example.test", "type": "False Positive", "category": "Benign",
    }).json["report"]
    admin_url = f"/api/v1/reports/{report['id']}"
    mobile_url = f"/api/v1/mobile/reports/{report['id']}"
    assert client.patch(admin_url, headers=headers, json={"status": "review"}).status_code == 200
    first = client.get(mobile_url, headers=mobile).json["report"]
    assert first["status_event_id"] and first["status_changed_at"]
    assert client.patch(admin_url, headers=headers, json={"admin_notes": "Catatan internal"}).status_code == 200
    assert client.get(mobile_url, headers=mobile).json["report"]["status_event_id"] == first["status_event_id"]
    assert client.patch(admin_url, headers=headers, json={"status": "rejected"}).status_code == 200
    assert client.get(mobile_url, headers=mobile).json["report"]["status_event_id"] > first["status_event_id"]
