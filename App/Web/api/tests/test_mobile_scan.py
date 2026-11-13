"""Inference endpoint: predictions come from the active artefact, not a stub."""
import pytest
from werkzeug.security import generate_password_hash

from app.extensions import db
from app.models import MLRun, MobileUser, Scan, now
from tests.stub_pipeline import CLASSES, write_pipeline

METRICS = {
    "validation": {
        "accuracy": 0.9,
        "balanced_accuracy": 0.9,
        "macro_f1": 0.9,
        "weighted_f1": 0.9,
    },
    "test": {
        "accuracy": 0.9,
        "balanced_accuracy": 0.9,
        "macro_f1": 0.9,
        "weighted_f1": 0.9,
    },
}


def _run(app, tmp_path, *, active=True, synthetic=False, digest=None, version=None):
    """Create an imported run pointing at a freshly written stub pipeline."""
    model_path = tmp_path / "models" / "svm_tfidf.pkl"
    model_path.parent.mkdir(parents=True, exist_ok=True)
    written = write_pipeline(model_path)
    with app.app_context():
        run = MLRun(
            id="run-test-000000000000000000000001",
            model="svm",
            representation="tfidf",
            status="completed",
            classes=CLASSES,
            metrics=METRICS,
            report={"validation": {}, "test": {}},
            confusion_matrix=[[1, 0], [0, 1]],
            split_counts={"train": 8, "validation": 0, "test": 0},
            params={},
            row_count=8,
            provenance={"is_synthetic": synthetic},
            artifact_path="models/svm_tfidf.pkl",
            artifact_sha256=digest if digest is not None else written,
            artifact_sklearn_version=version,
            is_active=active,
            completed_at=now(),
        )
        db.session.add(run)
        db.session.commit()
    return run


def _token(client, email="scanner@example.com", password="password-scanner-2026"):
    client.post(
        "/api/v1/mobile/auth/register",
        json={"name": "Scanner", "email": email, "password": password},
    )
    response = client.post(
        "/api/v1/mobile/auth/login", json={"email": email, "password": password}
    )
    return {"Authorization": f"Bearer {response.json['token']}"}


def test_scan_returns_a_prediction_and_stores_it(app, client, tmp_path):
    _run(app, tmp_path)
    headers = _token(client)

    response = client.post(
        "/api/v1/mobile/scan",
        json={"url": "https://paypal-login-secure.com/verify/account"},
        headers=headers,
    )
    assert response.status_code == 201
    scan = response.json["scan"]
    assert scan["category"] in CLASSES
    assert scan["score_kind"] == "margin"
    assert scan["model_run_id"] == "run-test-000000000000000000000001"

    with app.app_context():
        stored = db.session.get(Scan, scan["scan_id"])
        assert stored is not None
        # The scheme is stripped before the model sees the text.
        assert stored.url == "https://paypal-login-secure.com/verify/account"
        assert stored.model_input == "paypal-login-secure.com/verify/account"


def test_scheme_does_not_change_the_prediction(app, client, tmp_path):
    _run(app, tmp_path)
    headers = _token(client)

    bare = client.post(
        "/api/v1/mobile/scan", json={"url": "paypal-login-secure.com/verify/account"},
        headers=headers,
    )
    schemed = client.post(
        "/api/v1/mobile/scan",
        json={"url": "https://paypal-login-secure.com/verify/account"},
        headers=headers,
    )
    upper = client.post(
        "/api/v1/mobile/scan",
        json={"url": "HTTPS://PayPal-Login-Secure.COM/verify/account"},
        headers=headers,
    )
    assert bare.json["scan"]["category"] == schemed.json["scan"]["category"]
    assert bare.json["scan"]["category"] == upper.json["scan"]["category"]


def test_scan_requires_a_bearer_token(client):
    assert client.post("/api/v1/mobile/scan", json={"url": "x.test"}).status_code == 401


def test_scan_rejects_invalid_url(app, client, tmp_path):
    _run(app, tmp_path)
    headers = _token(client)
    assert client.post("/api/v1/mobile/scan", json={"url": ""}, headers=headers).status_code == 400
    assert (
        client.post("/api/v1/mobile/scan", json={"url": "x" * 2049}, headers=headers).status_code
        == 400
    )
    assert client.post("/api/v1/mobile/scan", json={}, headers=headers).status_code == 400


def test_scan_without_active_model_is_unavailable(app, client, tmp_path):
    _run(app, tmp_path, active=False)
    headers = _token(client)
    response = client.post("/api/v1/mobile/scan", json={"url": "google.com"}, headers=headers)
    assert response.status_code == 503
    assert response.json["error"]["code"] == "inference_unavailable"


def test_synthetic_model_cannot_predict(app, client, tmp_path):
    _run(app, tmp_path, synthetic=True)
    headers = _token(client)
    response = client.post("/api/v1/mobile/scan", json={"url": "google.com"}, headers=headers)
    assert response.status_code == 503


def test_checksum_mismatch_is_refused(app, client, tmp_path):
    _run(app, tmp_path, digest="0" * 64)
    headers = _token(client)
    response = client.post("/api/v1/mobile/scan", json={"url": "google.com"}, headers=headers)
    assert response.status_code == 503


def test_sklearn_version_mismatch_is_refused(app, client, tmp_path):
    _run(app, tmp_path, version="0.0.1")
    headers = _token(client)
    response = client.post("/api/v1/mobile/scan", json={"url": "google.com"}, headers=headers)
    assert response.status_code == 503


def test_missing_artifact_file_is_refused(app, client, tmp_path):
    _run(app, tmp_path)
    headers = _token(client)
    (tmp_path / "models" / "svm_tfidf.pkl").unlink()
    response = client.post("/api/v1/mobile/scan", json={"url": "google.com"}, headers=headers)
    assert response.status_code == 503


def test_scan_is_owned_by_the_caller(app, client, tmp_path):
    _run(app, tmp_path)
    owner = _token(client, email="owner@example.com")
    other = _token(client, email="other@example.com")

    created = client.post(
        "/api/v1/mobile/scan", json={"url": "google.com"}, headers=owner
    )
    scan_id = created.json["scan"]["scan_id"]

    with app.app_context():
        scan = db.session.get(Scan, scan_id)
        user = db.session.scalar(db.select(MobileUser).filter_by(email="owner@example.com"))
        assert scan.mobile_user_id == user.id


@pytest.fixture(autouse=True)
def _clear_inference_cache():
    """The pipeline cache is process-wide, so isolate every test."""
    from app.ml.inference import clear_cache

    clear_cache()
    yield
    clear_cache()
