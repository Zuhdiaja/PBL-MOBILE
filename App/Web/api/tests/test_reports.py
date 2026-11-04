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
        _seed_dataset(
            "test-dataset-uuid",
            ["url", "label", "source"],
            ["benign", "phishing"],
        )

    # Sync now
    sync_res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert sync_res.status_code == 200
    data = sync_res.json["report"]
    assert data["status"] == "completed"
    assert data["dataset_synced"] is True
    assert data["dataset_id"] == "test-dataset-uuid"

    # Verify row inserted into dataset_rows, using the spelling the dataset already uses.
    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(DatasetRow.dataset_id == "test-dataset-uuid", DatasetRow.row_number == 11)
        )
        assert row is not None
        assert row.values[0] == "bad-phish.test"
        assert row.values[1] == "phishing"


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


def _seed_dataset(dataset_id, columns, labels, count=10):
    """Create an active dataset with rows whose label column uses the given spellings."""
    dataset = Dataset(
        id=dataset_id,
        filename="murl_sample.csv",
        columns=columns,
        row_count=count,
    )
    db.session.add(dataset)
    for row_number in range(1, count + 1):
        values = ["seed-%d.test" % row_number for _ in columns]
        if labels:
            values[1] = labels[(row_number - 1) % len(labels)]
        db.session.add(
            DatasetRow(dataset_id=dataset_id, row_number=row_number, values=values)
        )
    state = db.session.get(DatasetState, 1) or DatasetState(id=1)
    state.active_id = dataset_id
    db.session.add(state)
    db.session.commit()


def _activate_dataset(app):
    with app.app_context():
        _seed_dataset(
            "idempotent-dataset-uuid",
            ["url", "label", "source"],
            ["benign", "phishing", "malware"],
        )


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
        # 10 seeded rows plus the single synced report; the retry added nothing.
        assert len(rows) == 11
        assert max(row.row_number for row in rows) == 11


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


def test_reports_pagination_rejects_unknown_page_size(authenticated):
    client, headers = authenticated
    res = client.get("/api/v1/reports?page_size=13", headers=headers)
    assert res.status_code == 400
    assert res.json["error"]["code"] == "invalid_pagination"


def test_reports_honour_page_size(authenticated):
    client, headers = authenticated
    for index in range(30):
        client.post(
            "/api/v1/reports/submit",
            json={"url": f"page-size-{index}.test", "type": "False Positive", "category": "Benign"},
        )

    res = client.get("/api/v1/reports?page_size=50", headers=headers)
    assert res.status_code == 200
    assert res.json["page_size"] == 50
    assert len(res.json["items"]) == 30
    assert res.json["page_count"] == 1

    first_page = client.get("/api/v1/reports?page_size=25", headers=headers).json
    assert first_page["page_size"] == 25
    assert len(first_page["items"]) == 25
    assert first_page["page_count"] == 2


def test_reports_reject_unknown_status(authenticated):
    client, headers = authenticated
    res = client.get("/api/v1/reports?status=bogus", headers=headers)
    assert res.status_code == 400
    assert res.json["error"]["code"] == "invalid_status"


def test_summary_counts_rejected_and_filter_works(authenticated):
    client, headers = authenticated
    keep = client.post(
        "/api/v1/reports/submit",
        json={"url": "reject-me.test", "type": "False Negative", "category": "Phishing"},
    ).json["report"]["id"]
    client.post(
        "/api/v1/reports/submit",
        json={"url": "keep-open.test", "type": "False Positive", "category": "Benign"},
    )

    client.patch(f"/api/v1/reports/{keep}", json={"status": "rejected"}, headers=headers)

    listing = client.get("/api/v1/reports", headers=headers).json
    assert listing["summary"]["rejected"] == 1
    assert listing["summary"]["submitted"] == 1
    assert listing["summary"]["total"] == 2

    filtered = client.get("/api/v1/reports?status=rejected", headers=headers).json
    assert filtered["row_count"] == 1
    assert filtered["items"][0]["id"] == keep


def test_notes_length_is_bounded(authenticated):
    client, headers = authenticated
    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "long-notes.test", "type": "False Positive", "category": "Benign", "notes": "x" * 2001},
    )
    assert res.status_code == 400
    assert res.json["error"]["code"] == "invalid_notes"

    ok = client.post(
        "/api/v1/reports/submit",
        json={"url": "ok-notes.test", "type": "False Positive", "category": "Benign", "notes": "x" * 2000},
    )
    assert ok.status_code == 201

    report_id = ok.json["report"]["id"]
    too_long = client.patch(
        f"/api/v1/reports/{report_id}",
        json={"admin_notes": "y" * 2001},
        headers=headers,
    )
    assert too_long.status_code == 400
    assert too_long.json["error"]["code"] == "invalid_notes"

    non_string = client.post(
        "/api/v1/reports/submit",
        json={"url": "bad-notes.test", "type": "False Positive", "category": "Benign", "notes": ["a"]},
    )
    assert non_string.status_code == 400
    assert non_string.json["error"]["code"] == "invalid_notes"


def test_search_treats_wildcards_literally(authenticated):
    client, headers = authenticated
    client.post(
        "/api/v1/reports/submit",
        json={"url": "plain-alpha.test", "type": "False Positive", "category": "Benign"},
    )
    client.post(
        "/api/v1/reports/submit",
        json={"url": "discount-100%.test", "type": "False Negative", "category": "Phishing"},
    )

    wildcard = client.get("/api/v1/reports?search=%25", headers=headers).json
    assert wildcard["row_count"] == 1
    assert wildcard["items"][0]["url"] == "discount-100%.test"


    long_term = client.get(f"/api/v1/reports?search={'z' * 500}", headers=headers)
    assert long_term.status_code == 200
    assert long_term.json["row_count"] == 0


def test_submit_normalizes_known_category_aliases(authenticated):
    client, headers = authenticated
    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "alias.test", "type": "False Positive", "category": "Aman / Benign"},
    )
    assert res.status_code == 201
    assert res.json["report"]["reported_category"] == "Benign"


def test_sync_rejects_unknown_category(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    res = client.post(
        "/api/v1/reports/submit",
        json={"url": "other-cat.test", "type": "False Negative", "category": "Lainnya"},
    )
    report_id = res.json["report"]["id"]
    assert res.json["report"]["reported_category"] == "Lainnya"

    sync = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert sync.status_code == 409
    assert sync.json["error"]["code"] == "invalid_category"


def test_sync_requires_category_consistent_with_report_type(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    wrong = client.post(
        "/api/v1/reports/submit",
        json={"url": "mismatch-fp.test", "type": "False Positive", "category": "Phishing"},
    ).json["report"]["id"]
    res = client.post(f"/api/v1/reports/{wrong}/sync-dataset", headers=headers)
    assert res.status_code == 409
    assert res.json["error"]["code"] == "inconsistent_report"

    wrong_fn = client.post(
        "/api/v1/reports/submit",
        json={"url": "mismatch-fn.test", "type": "False Negative", "category": "Benign"},
    ).json["report"]["id"]
    res = client.post(f"/api/v1/reports/{wrong_fn}/sync-dataset", headers=headers)
    assert res.status_code == 409
    assert res.json["error"]["code"] == "inconsistent_report"

    good = client.post(
        "/api/v1/reports/submit",
        json={"url": "match-fn.test", "type": "False Negative", "category": "Malware"},
    ).json["report"]["id"]
    ok = client.post(f"/api/v1/reports/{good}/sync-dataset", headers=headers)
    assert ok.status_code == 200

    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "idempotent-dataset-uuid",
                DatasetRow.row_number == ok.json["row_number"],
            )
        )
        assert row.values[1] == "malware"


def test_sync_requires_url_column(app, authenticated):
    client, headers = authenticated

    with app.app_context():
        dataset = Dataset(
            id="no-url-dataset-uuid",
            filename="features.csv",
            columns=["label", "domain", "source"],
            row_count=3,
        )
        db.session.add(dataset)
        state = db.session.get(DatasetState, 1) or DatasetState(id=1)
        state.active_id = dataset.id
        db.session.add(state)
        db.session.commit()

    report_id = client.post(
        "/api/v1/reports/submit",
        json={"url": "no-url.test", "type": "False Negative", "category": "Phishing"},
    ).json["report"]["id"]

    res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert res.status_code == 409
    assert res.json["error"]["code"] == "unsupported_dataset"

    with app.app_context():
        assert db.session.get(Dataset, "no-url-dataset-uuid").row_count == 3


def test_sync_uses_dataset_label_spelling(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        _seed_dataset(
            "spelling-dataset-uuid",
            ["url", "label", "source"],
            ["benign", "phishing", "Exploit"],
        )

    lower = client.post(
        "/api/v1/reports/submit",
        json={"url": "spell-lower.test", "type": "False Negative", "category": "Phishing"},
    ).json["report"]["id"]
    upper = client.post(
        "/api/v1/reports/submit",
        json={"url": "spell-upper.test", "type": "False Negative", "category": "Exploit"},
    ).json["report"]["id"]

    first = client.post(f"/api/v1/reports/{lower}/sync-dataset", headers=headers)
    second = client.post(f"/api/v1/reports/{upper}/sync-dataset", headers=headers)
    assert first.status_code == 200
    assert second.status_code == 200

    with app.app_context():
        rows = db.session.scalars(
            db.select(DatasetRow)
            .where(DatasetRow.dataset_id == "spelling-dataset-uuid", DatasetRow.row_number > 10)
            .order_by(DatasetRow.row_number)
        ).all()
        assert [row.values[1] for row in rows] == ["phishing", "Exploit"]


def test_sync_writes_benign_for_safe_reports(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    report_id = client.post(
        "/api/v1/reports/submit",
        json={"url": "safe-claim.test", "type": "False Positive", "category": "Benign"},
    ).json["report"]["id"]

    res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert res.status_code == 200

    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "idempotent-dataset-uuid",
                DatasetRow.row_number == res.json["row_number"],
            )
        )
        assert row.values[1] == "benign"


def test_legitimate_alias_maps_to_benign(app, authenticated):
    client, headers = authenticated
    _activate_dataset(app)

    submitted = client.post(
        "/api/v1/reports/submit",
        json={"url": "legit-claim.test", "type": "False Positive", "category": "legitimate"},
    )
    assert submitted.status_code == 201
    assert submitted.json["report"]["reported_category"] == "Benign"

    res = client.post(
        f"/api/v1/reports/{submitted.json['report']['id']}/sync-dataset",
        headers=headers,
    )
    assert res.status_code == 200

    with app.app_context():
        row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "idempotent-dataset-uuid",
                DatasetRow.row_number == res.json["row_number"],
            )
        )
        assert row.values[1] == "benign"


def test_sync_rejects_category_missing_from_dataset(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        _seed_dataset(
            "narrow-dataset-uuid",
            ["url", "label"],
            ["benign", "phishing"],
        )

    report_id = client.post(
        "/api/v1/reports/submit",
        json={"url": "no-malware-class.test", "type": "False Negative", "category": "Malware"},
    ).json["report"]["id"]

    res = client.post(f"/api/v1/reports/{report_id}/sync-dataset", headers=headers)
    assert res.status_code == 409
    assert res.json["error"]["code"] == "unsupported_dataset"


def test_label_cache_is_scoped_per_dataset(app, authenticated):
    client, headers = authenticated

    with app.app_context():
        _seed_dataset("first-dataset-uuid", ["url", "label"], ["benign", "phishing"])
    first = client.post(
        "/api/v1/reports/submit",
        json={"url": "cache-first.test", "type": "False Negative", "category": "Phishing"},
    ).json["report"]["id"]
    assert client.post(f"/api/v1/reports/{first}/sync-dataset", headers=headers).status_code == 200

    with app.app_context():
        _seed_dataset("second-dataset-uuid", ["url", "label"], ["Benign", "Phishing"])
    second = client.post(
        "/api/v1/reports/submit",
        json={"url": "cache-second.test", "type": "False Negative", "category": "Phishing"},
    ).json["report"]["id"]
    assert client.post(f"/api/v1/reports/{second}/sync-dataset", headers=headers).status_code == 200

    with app.app_context():
        first_row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "first-dataset-uuid", DatasetRow.row_number == 11
            )
        )
        second_row = db.session.scalar(
            db.select(DatasetRow).where(
                DatasetRow.dataset_id == "second-dataset-uuid", DatasetRow.row_number == 11
            )
        )
        assert first_row.values[1] == "phishing"
        assert second_row.values[1] == "Phishing"
