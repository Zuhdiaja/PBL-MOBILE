import io
import json
from pathlib import Path
from datetime import datetime, timedelta, timezone

from app.extensions import db
from app.models import Dataset, DatasetRow, DatasetState, MLRun

FIXTURE = Path(__file__).parent / "fixtures" / "svm_tfidf_metrics.json"
RUN_ID = "test-run-000000000000000000000001"


def _upload(client, headers, filename="svm_tfidf_metrics.json", payload=None):
    content = payload if payload is not None else FIXTURE.read_bytes()
    return client.post(
        "/api/v1/ml/runs/import",
        data={"file": (io.BytesIO(content), filename)},
        headers=headers,
        content_type="multipart/form-data",
    )


def _seed_dataset(dataset_id, columns, values):
    dataset = Dataset(
        id=dataset_id,
        filename="murl_sample.csv",
        columns=columns,
        row_count=len(values),
    )
    db.session.add(dataset)
    for index, row in enumerate(values, start=1):
        db.session.add(DatasetRow(dataset_id=dataset_id, row_number=index, values=row))
    state = db.session.get(DatasetState, 1) or DatasetState(id=1)
    state.active_id = dataset_id
    db.session.add(state)
    db.session.commit()


def test_ml_endpoints_require_session(client):
    assert client.get("/api/v1/ml/status").status_code == 401
    assert client.get("/api/v1/ml/runs").status_code == 401
    assert client.get(f"/api/v1/ml/runs/{RUN_ID}").status_code == 401
    assert client.get("/api/v1/ml/dataset-summary").status_code == 401
    assert client.get("/api/v1/ml/preprocessing-examples").status_code == 401


def test_import_list_and_detail(authenticated):
    client, headers = authenticated
    response = _upload(client, headers)
    assert response.status_code == 201
    run = response.json["run"]
    assert run["id"] == RUN_ID
    assert run["dataset_matches"] is None
    assert run["model"] == "svm"
    assert run["metrics"]["test"]["accuracy"] == 0.81
    assert len(run["confusion_matrix"]) == 3
    assert run["params"]["seed"] == 42

    listing = client.get("/api/v1/ml/runs", headers=headers)
    assert listing.status_code == 200
    assert listing.json["active_id"] is None
    assert listing.json["items"][0]["id"] == RUN_ID
    assert "confusion_matrix" not in listing.json["items"][0]

    detail = client.get(f"/api/v1/ml/runs/{RUN_ID}", headers=headers)
    assert detail.status_code == 200
    assert detail.json["run"]["report"]["test"]["benign"]["f1-score"] == 0.8621
    assert detail.json["run"]["split_counts"]["train"] == 750


def test_status_and_paginated_history(app, authenticated):
    client, _ = authenticated
    now = datetime.now(timezone.utc)
    with app.app_context():
        db.session.add_all([
            MLRun(
                id=f"history-{index}", model="svm", representation="tfidf",
                row_count=100, completed_at=now + timedelta(seconds=index),
                is_active=index == 0,
            )
            for index in range(23)
        ])
        db.session.commit()

    status = client.get("/api/v1/ml/status").json
    assert status["active_id"] == status["run"]["id"] == "history-0"
    assert "items" not in status
    assert "confusion_matrix" not in status["run"]
    first = client.get("/api/v1/ml/runs").json
    second = client.get("/api/v1/ml/runs?page=2").json
    assert first["active_id"] == second["active_id"] == "history-0"
    assert first["has_next"] and not second["has_next"]
    assert [run["id"] for run in first["items"]] == [f"history-{index}" for index in range(22, 2, -1)]
    assert [run["id"] for run in second["items"]] == ["history-2", "history-1", "history-0"]
    assert client.get("/api/v1/ml/runs?page=0").status_code == 400
    assert client.get("/api/v1/ml/runs?page=bad").status_code == 400


def test_import_validates_train_class_counts(authenticated):
    client, headers = authenticated
    artifact = json.loads(FIXTURE.read_text(encoding="utf-8"))
    artifact["train_class_counts"] = {"benign": 400, "phishing": 250, "malware": 100}
    response = _upload(client, headers, payload=json.dumps(artifact).encode())
    assert response.status_code == 201
    expected = artifact["train_class_counts"].copy()
    assert response.json["run"]["provenance"]["train_class_counts"] == expected

    artifact["train_class_counts"]["malware"] = 99
    rejected = _upload(client, headers, payload=json.dumps(artifact).encode())
    assert rejected.status_code == 400
    assert "train_class_counts" in rejected.json["error"]["message"]
    detail = client.get(f"/api/v1/ml/runs/{RUN_ID}").json["run"]
    assert detail["provenance"]["train_class_counts"] == expected


def test_import_replaces_existing_run(app, authenticated):
    client, headers = authenticated
    assert _upload(client, headers).status_code == 201
    changed = json.loads(FIXTURE.read_text(encoding="utf-8"))
    changed["fit_seconds"] = 99.0
    response = _upload(client, headers, payload=json.dumps(changed).encode())
    assert response.status_code == 201
    assert response.json["run"]["fit_seconds"] == 99.0
    with app.app_context():
        assert db.session.scalar(db.select(db.func.count()).select_from(MLRun)) == 1


def test_import_rejects_invalid_file(authenticated):
    client, headers = authenticated
    wrong_extension = _upload(client, headers, filename="metrics.txt")
    assert wrong_extension.status_code == 400
    assert wrong_extension.json["error"]["code"] == "invalid_file"

    malformed = _upload(client, headers, payload=b"{not-json")
    assert malformed.status_code == 400
    assert malformed.json["error"]["code"] == "invalid_artifact"

    missing = _upload(client, headers, payload=json.dumps({"model": "svm"}).encode())
    assert missing.status_code == 400
    assert missing.json["error"]["code"] == "invalid_artifact"

    broken_matrix = json.loads(FIXTURE.read_text(encoding="utf-8"))
    broken_matrix["test_confusion_matrix"][0][0] += 1
    mismatch = _upload(client, headers, payload=json.dumps(broken_matrix).encode())
    assert mismatch.status_code == 400
    assert mismatch.json["error"]["code"] == "invalid_artifact"

    too_large = _upload(client, headers, payload=b"x" * (2 * 1024 * 1024 + 1))
    assert too_large.status_code == 413
    assert too_large.json["error"]["code"] == "file_too_large"


def test_run_detail_not_found(authenticated):
    client, headers = authenticated
    response = client.get("/api/v1/ml/runs/missing", headers=headers)
    assert response.status_code == 404
    assert response.json["error"]["code"] == "run_not_found"


def test_preview_normalizes_and_tokenizes(authenticated):
    client, headers = authenticated
    response = client.post(
        "/api/v1/ml/preview",
        json={"url": "HTTP://BÜCHER.example./verify?x=1"},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json
    assert data["normalized"]["scheme"] == "http"
    assert data["normalized"]["canonical_host"] == "xn--bcher-kva.example"
    assert "lowercase_scheme" in data["steps"]
    assert "idna" in data["steps"]
    assert data["ngrams"]["total_tokens"] > 0
    # The model never sees a scheme, so the tokenised text is lower-case bare.
    # The trailing root dot stays: only the scheme and case are normalised.
    assert data["model_input"] == "bücher.example./verify?x=1"
    assert "://" not in data["model_input"]

    ip = client.post(
        "/api/v1/ml/preview",
        json={"url": "http://127.0.0.1:8080/login"},
        headers=headers,
    )
    assert ip.status_code == 200
    assert ip.json["normalized"]["is_ip"] is True
    assert ip.json["normalized"]["site"] == "ip:127.0.0.1"

    assert client.post("/api/v1/ml/preview", json={"url": ""}, headers=headers).status_code == 400
    assert client.post("/api/v1/ml/preview", json={"url": "x" * 2049}, headers=headers).status_code == 400


def test_dataset_summary_without_dataset(authenticated):
    client, headers = authenticated
    response = client.get("/api/v1/ml/dataset-summary", headers=headers)
    assert response.status_code == 404
    assert response.json["error"]["code"] == "no_dataset"


def test_dataset_summary_counts_labels(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        _seed_dataset(
            "ml-dataset",
            ["url", "label", "source"],
            [
                ["safe.test", "benign", "seed"],
                ["safe-2.test", "benign", "seed"],
                ["phish.test", "phishing", "seed"],
                ["bad.test", "malware", "seed"],
            ],
        )

    response = client.get("/api/v1/ml/dataset-summary", headers=headers)
    assert response.status_code == 200
    assert response.json["label_column"] == "label"
    counts = {item["label"]: item["count"] for item in response.json["class_counts"]}
    assert counts == {"benign": 2, "malware": 1, "phishing": 1}


def test_dataset_summary_without_label_column(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        _seed_dataset("ml-dataset-no-label", ["url", "source"], [["a.test", "seed"]])

    response = client.get("/api/v1/ml/dataset-summary", headers=headers)
    assert response.status_code == 200
    assert response.json["label_column"] is None
    assert response.json["class_counts"] == []


def test_preprocessing_examples_use_changed_rows_from_active_csv(app, authenticated):
    client, headers = authenticated
    source_url = "HTTPS://Docs.Example.COM./Guide"
    with app.app_context():
        _seed_dataset("ml-csv", ["url", "type"], [
            ["already-clean.example", "benign"],
            [" example.com/a\xa0", " BENIGN "],
            ["https://[broken]/", "benign"],
            [source_url, "benign"],
        ])

    response = client.get("/api/v1/ml/preprocessing-examples?dataset_id=ml-csv", headers=headers)
    assert response.status_code == 200
    assert response.json["cleaning"] == {
        "row_number": 2, "url": " example.com/a\xa0", "label": " BENIGN ",
        "clean_url": "example.com/a", "clean_label": "benign",
    }
    expected = client.post("/api/v1/ml/preview", json={"url": source_url}, headers=headers)
    assert expected.status_code == 200
    assert response.json["normalization"] == {"row_number": 4, "preview": expected.json}


def test_preprocessing_examples_for_clean_csv_and_outdated_dataset_id(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        _seed_dataset("ml-csv", ["url"], [["example.com/a"]])

    response = client.get("/api/v1/ml/preprocessing-examples?dataset_id=ml-csv", headers=headers)
    assert response.status_code == 200
    assert response.json == {"cleaning": None, "normalization": None}
    outdated = client.get("/api/v1/ml/preprocessing-examples?dataset_id=previous", headers=headers)
    assert outdated.status_code == 409


def test_cli_imports_artifact(app, tmp_path):
    path = tmp_path / "svm_tfidf_metrics.json"
    path.write_bytes(FIXTURE.read_bytes())
    runner = app.test_cli_runner()
    result = runner.invoke(args=["ml-import", "--path", str(path)])
    assert result.exit_code == 0, result.output
    assert RUN_ID in result.output
    with app.app_context():
        run = db.session.get(MLRun, RUN_ID)
        assert run is not None
        assert run.classes == ["benign", "phishing", "malware"]


def test_preview_tokenizes_the_model_input(authenticated):
    client, headers = authenticated
    response = client.post(
        "/api/v1/ml/preview",
        json={"url": "HTTPS://Example.COM/Login"},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json
    assert data["model_input"] == "example.com/login"
    # N-grams must describe the model input, never the schemed display text.
    tokens = [item["token"] for item in data["ngrams"]["3"]]
    assert "htt" not in tokens
    assert "://" not in tokens
    assert "exa" in tokens
