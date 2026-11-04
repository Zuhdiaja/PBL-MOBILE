import os
from pathlib import Path

import pytest

from app.services import url_model

PREDICT = "/api/v1/mobile/predict"


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def sign_up(client, email="predict@example.com", password="password-predict-2026"):
    response = client.post(
        "/api/v1/mobile/auth/register",
        json={"name": "Predict User", "email": email, "password": password},
    )
    assert response.status_code == 201
    return response.get_json()["token"]


class StubPipeline:
    """Mimics the fitted pipeline: fixed classes, fixed decision values."""

    def __init__(self, label="phishing"):
        self.label = label
        self.inputs = []
        self.named_steps = {"classifier": self}
        self.classes_ = ["benign", "defacement", "exploit", "legitimate",
                         "malware", "phishing", "spam"]
        self.n_features_in_ = url_model.EXPECTED_FEATURES

    def decision_function(self, inputs):
        self.inputs.extend(inputs)
        rows = []
        for _ in inputs:
            row = [0.0] * len(self.classes_)
            row[self.classes_.index(self.label)] = 5.0
            rows.append(row)
        return rows


def install_stub(app, label="phishing"):
    pipeline = StubPipeline(label)
    app.extensions["url_model"] = pipeline
    return pipeline


def test_requires_bearer_token(client):
    response = client.post(PREDICT, json={"urls": ["contoh.test"]})
    assert response.status_code == 401
    assert response.get_json()["error"]["code"] == "unauthorized"


def test_rejects_empty_list(app, client):
    token = sign_up(client)
    response = client.post(PREDICT, json={"urls": []}, headers=bearer(token))
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_urls"


def test_rejects_missing_or_non_list_payload(app, client):
    token = sign_up(client)
    for payload in ({}, {"urls": "contoh.test"}, {"urls": {"a": 1}}):
        response = client.post(PREDICT, json=payload, headers=bearer(token))
        assert response.status_code == 400
        assert response.get_json()["error"]["code"] == "invalid_urls"


def test_rejects_more_than_fifty_urls(app, client):
    token = sign_up(client)
    response = client.post(
        PREDICT,
        json={"urls": [f"contoh-{i}.test" for i in range(51)]},
        headers=bearer(token),
    )
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_urls"


def test_rejects_non_string_and_blank_entries(app, client):
    token = sign_up(client)
    for entry in (123, None, ["nested"], "   ", ""):
        response = client.post(PREDICT, json={"urls": [entry]}, headers=bearer(token))
        assert response.status_code == 400
        assert response.get_json()["error"]["code"] == "invalid_urls"


def test_rejects_url_longer_than_limit(app, client):
    token = sign_up(client)
    response = client.post(
        PREDICT, json={"urls": ["a" * 2049]}, headers=bearer(token)
    )
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_urls"

    # Exactly at the limit the request passes validation, so it may only fail
    # later with 503 when no model is loaded.
    install_stub(app, "benign")
    accepted = client.post(
        PREDICT, json={"urls": ["a" * 2048]}, headers=bearer(token)
    )
    assert accepted.status_code == 200


def test_reports_model_unavailable(app, client):
    app.extensions["url_model"] = None
    token = sign_up(client)
    response = client.post(PREDICT, json={"urls": ["contoh.test"]}, headers=bearer(token))
    assert response.status_code == 503
    assert response.get_json()["error"]["code"] == "model_unavailable"


def test_returns_predictions_with_canonical_categories(app, client):
    install_stub(app, "phishing")
    token = sign_up(client)
    response = client.post(
        PREDICT, json={"urls": ["contoh.test", "lain.test"]}, headers=bearer(token)
    )
    assert response.status_code == 200
    data = response.get_json()

    assert [item["url"] for item in data["predictions"]] == ["contoh.test", "lain.test"]
    assert [item["raw_label"] for item in data["predictions"]] == ["phishing", "phishing"]
    assert [item["category"] for item in data["predictions"]] == ["Phishing", "Phishing"]
    for item in data["predictions"]:
        assert set(item) == {"url", "raw_label", "category", "confidence"}
        assert 0.0 <= item["confidence"] <= 1.0

    assert data["model"]["name"] == "svm_tfidf"
    assert data["model"]["n_features"] == url_model.EXPECTED_FEATURES
    assert data["model"]["classes"] == ["benign", "defacement", "exploit",
                                        "legitimate", "malware", "phishing", "spam"]


def test_maps_every_raw_label_to_a_canonical_category(app, client):
    token = sign_up(client)
    expected = {
        "benign": "Benign",
        "legitimate": "Benign",
        "phishing": "Phishing",
        "malware": "Malware",
        "spam": "Spam",
        "defacement": "Defacement",
        "exploit": "Exploit",
    }
    for raw, category in expected.items():
        install_stub(app, raw)
        response = client.post(PREDICT, json={"urls": ["contoh.test"]}, headers=bearer(token))
        assert response.status_code == 200
        item = response.get_json()["predictions"][0]
        assert item["raw_label"] == raw
        assert item["category"] == category


def test_normalizes_scheme_and_case_before_predicting(app, client):
    pipeline = install_stub(app, "benign")
    token = sign_up(client)
    client.post(
        PREDICT,
        json={"urls": ["HTTPS://Contoh.Test/Path", "http://contoh.test/path"]},
        headers=bearer(token),
    )
    assert pipeline.inputs == ["contoh.test/path", "contoh.test/path"]


def test_echoes_the_original_url_not_the_normalized_one(app, client):
    install_stub(app, "benign")
    token = sign_up(client)
    response = client.post(
        PREDICT, json={"urls": ["HTTPS://Contoh.Test"]}, headers=bearer(token)
    )
    assert response.get_json()["predictions"][0]["url"] == "HTTPS://Contoh.Test"


def test_normalize_only_removes_http_schemes():
    assert url_model.normalize("  HTTPS://Example.COM/A  ") == "example.com/a"
    assert url_model.normalize("ftp://example.com") == "ftp://example.com"
    assert url_model.normalize("www.example.com") == "www.example.com"


@pytest.mark.skipif(
    not (Path(__file__).resolve().parents[1] / "instance" / "models"
         / "svm_tfidf_pipeline.joblib").is_file()
    and not os.environ.get("URL_MODEL_PATH"),
    reason="artefak model tidak tersedia",
)
def test_predicts_with_the_real_model(app, client):
    app.extensions["url_model"] = url_model.load(app)
    assert app.extensions["url_model"] is not None

    token = sign_up(client)
    response = client.post(
        PREDICT,
        json={"urls": ["google.com", "https://paypal-verify.example.tk/login",
                       "free-iphone-winner.xyz/claim"]},
        headers=bearer(token),
    )
    assert response.status_code == 200
    data = response.get_json()
    canonical = {"Benign", "Phishing", "Malware", "Spam", "Defacement", "Exploit"}
    assert len(data["predictions"]) == 3
    for item in data["predictions"]:
        assert item["category"] in canonical
        assert 0.0 <= item["confidence"] <= 1.0
