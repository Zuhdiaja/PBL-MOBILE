import pytest
from app.extensions import db
from app.models import Dataset, DatasetRow, DatasetState, PredictionReport


def test_public_submit_report(client):
    response = client.post(
        "/api/v1/reports/submit",
        json={
            "url": "phishing-bank.test",
            "type": "False Negative",
            "category": "Phishing",
            "notes": "URL ini meniru halaman login bank.",
            "reporter_email": "user@example.test",
        },
    )
    assert response.status_code == 201
    data = response.json["report"]
    assert data["url"] == "phishing-bank.test"
    assert data["report_type"] == "False Negative"
    assert data["reported_category"] == "Phishing"
    assert data["status"] == "submitted"
    assert data["dataset_synced"] is False


def test_submit_report_validation(client):
    # Invalid type
    res = client.post("/api/v1/reports/submit", json={"url": "test.com", "type": "BadType", "category": "Phishing"})
    assert res.status_code == 400

    # Empty url
    res = client.post("/api/v1/reports/submit", json={"url": "", "type": "False Positive", "category": "Benign"})
    assert res.status_code == 400


def test_admin_reports_management(authenticated):
    client, headers = authenticated

    # Submit 2 reports first
    client.post(
        "/api/v1/reports/submit",
        json={"url": "safe-site.test", "type": "False Positive", "category": "Benign", "notes": "Ini situs resmi."},
    )
    client.post(
        "/api/v1/reports/submit",
        json={"url": "malware-download.test", "type": "False Negative", "category": "Malware"},
    )

    # Admin list reports
    list_res = client.get("/api/v1/reports", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json["items"]
    assert len(items) == 2
    summary = list_res.json["summary"]
    assert summary["total"] == 2
    assert summary["submitted"] == 2

    report_id = items[0]["id"]

    # Admin view detail
    detail_res = client.get(f"/api/v1/reports/{report_id}", headers=headers)
    assert detail_res.status_code == 200
    assert detail_res.json["report"]["id"] == report_id

    # Admin update status to 'review' with notes
    patch_res = client.patch(
        f"/api/v1/reports/{report_id}",
        json={"status": "review", "admin_notes": "Sedang dianalisis oleh analis keamanan."},
        headers=headers,
    )
    assert patch_res.status_code == 200
    assert patch_res.json["report"]["status"] == "review"
    assert patch_res.json["report"]["admin_notes"] == "Sedang dianalisis oleh analis keamanan."


def test_admin_sync_dataset(app, authenticated):
    client, headers = authenticated

    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "bad-phish.test", "type": "False Negative", "category": "Phishing"},
    )
    report_id = res.json["report"]["id"]

    # Attempt sync before active dataset exists
    sync_res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert sync_res.status_code == 400
    assert sync_res.json["error"]["code"] == "no_active_dataset"

    # Setup an active dataset
    with app.app_context():
        dataset = Dataset(
            id="test-dataset-uuid",
            filename="murl_sample.csv",
            columns=["url", "label", "source"],
            row_count=10,
        )
        db.session.add(dataset)
        state = db.session.get(DatasetState, 1) or DatasetState(id=1)
        state.active_id = dataset.id
        db.session.add(state)
        db.session.commit()

    # Sync now
    sync_res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert sync_res.status_code == 200
    data = sync_res.json["report"]
    assert data["status"] == "completed"
    assert data["dataset_synced"] is True
    assert data["dataset_id"] == "test-dataset-uuid"

    # Verify row inserted into dataset_rows
    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(DatasetRow.dataset_id == "test-dataset-uuid", DatasetRow.row_number == 11)
        )
        assert row is not None
        assert row.values[0] == "bad-phish.test"
        assert row.values[1] == "Phishing"


def test_admin_delete_report(authenticated):
    client, headers = authenticated
    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "delete-me.test", "type": "False Positive", "category": "Benign"},
    )
    report_id = res.json["report"]["id"]

    del_res = client.delete(f"/api/v1/reports/{report_id}", headers=headers)
    assert del_res.status_code == 200

    # Ensure not found
    get_res = client.get(f"/api/v1/reports/{report_id}", headers=headers)
    assert get_res.status_code == 404


def _activate_dataset(app):
    with app.app_context():
        dataset = Dataset(
            id="idempotent-dataset-uuid",
            filename="murl_sample.csv",
            columns=["url", "label", "source"],
            row_count=10,
        )
        db.session.add(dataset)
        state = db.session.get(DatasetState, 1) or DatasetState(id=1)
        state.active_id = dataset.id
        db.session.add(state)
        db.session.commit()


def test_sync_dataset_is_idempotent(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "twice-sync.test", "type": "False Negative", "category": "Phishing"},
    )
    report_id = res.json["report"]["id"]

    first = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert first.status_code == 200
    assert first.json["row_number"] == 11

    second = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert second.status_code == 409
    assert second.json["error"]["code"] == "already_synced"

    # The dataset must not grow on the rejected retry.
    with app.app_context():
        dataset = db.session.get(Dataset, "idempotent-dataset-uuid")
        assert dataset.row_count == 11
        rows = db.session.scalars(
            db.select(DatasetRow).where(DatasetRow.dataset_id == "idempotent-dataset-uuid")
        ).all()
        assert len(rows) == 1
        assert rows[0].row_number == 11


def test_cannot_delete_synced_report(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "keep-me.test", "type": "False Positive", "category": "Benign"},
    )
    report_id = res.json["report"]["id"]

    sync_res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert sync_res.status_code == 200

    del_res = client.delete(f"/api/v1/reports/{report_id}", headers=headers)
    assert del_res.status_code == 409
    assert del_res.json["error"]["code"] == "report_synced"

    # The report and its dataset row both survive.
    get_res = client.get(f"/api/v1/reports/{report_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json["report"]["dataset_synced"] is True

    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "idempotent-dataset-uuid",
                DatasetRow.row_number == 11,
            )
        )
        assert row is not None
