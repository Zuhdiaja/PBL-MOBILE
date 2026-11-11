import json
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace

import pytest

from app.ml.artifacts import ArtifactError, parse_artifact
from app.ml.dataset_binding import dataset_digest
from app.ml.ngrams import char_ngrams
from app.ml.normalize import normalize_url

FIXTURE = Path(__file__).parent / "fixtures" / "svm_tfidf_metrics.json"
SYNTHETIC_FIXTURE = Path(__file__).parent / "fixtures" / "svm_tfidf_metrics_synthetic.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_normalize_uppercase_scheme_and_ip():
    result = normalize_url("  HTTP://PayPal-Login.COM.%2F@127.0.0.1/verify?x=1\x00")
    assert result["scheme"] == "http"
    assert result["host"] == "127.0.0.1"
    assert result["canonical_host"] == "127.0.0.1"
    assert result["is_ip"] is True
    assert result["site"] == "ip:127.0.0.1"
    assert "trim" in result["steps"]
    assert "lowercase_scheme" in result["steps"]
    assert "ip_literal" in result["steps"]
    assert result["parse_failed"] is False


def test_normalize_percent_encoded_host_and_punycode():
    percent = normalize_url("http://exa%6dple.com/path")
    assert percent["canonical_host"] == "example.com"
    assert "percent_decode" in percent["steps"]

    punycode = normalize_url("https://bücher.de/path")
    assert punycode["canonical_host"] == "xn--bcher-kva.de"
    assert "idna" in punycode["steps"]
    assert punycode["site"] == "xn--bcher-kva.de"


def test_normalize_ipv6_and_root_dot():
    ipv6 = normalize_url("http://[::1]:8080/")
    assert ipv6["canonical_host"] == "::1"
    assert ipv6["is_ip"] is True
    assert ipv6["text"] == "http://[::1]/"

    dotted = normalize_url("https://example.com./login")
    assert dotted["canonical_host"] == "example.com"
    assert "strip_root_dot" in dotted["steps"]


def test_normalize_never_raises_for_odd_input():
    for value in (None, "", "   ", "\x00", "http://[::1", "not a url", "http://"):
        result = normalize_url(value)
        assert isinstance(result, dict)
        assert isinstance(result["steps"], list)
        assert isinstance(result["parse_failed"], bool)


def test_char_ngrams_counts_windows():
    result = char_ngrams("aaaa", sizes=(3, 4), limit=5)
    assert result["3"] == [{"token": "aaa", "count": 2}]
    assert result["4"] == [{"token": "aaaa", "count": 1}]
    assert result["total_tokens"] == 3


def test_parse_artifact_valid():
    payload = parse_artifact(load(FIXTURE))
    assert payload["id"] == "test-run-000000000000000000000001"
    assert payload["classes"] == ["benign", "phishing", "malware"]
    assert payload["metrics"]["test"]["accuracy"] == 0.81
    assert sum(sum(row) for row in payload["confusion_matrix"]) == 100
    assert payload["params"]["seed"] == 42
    assert payload["provenance"]["is_synthetic"] is False


def test_parse_artifact_accepts_synthetic_matrix():
    payload = parse_artifact(load(SYNTHETIC_FIXTURE))
    assert payload["provenance"]["is_synthetic"] is True
    assert "rekonstruksi" in payload["provenance"]["example_notice"]
    # Structural checks still apply to a reconstructed matrix.
    assert sum(sum(row) for row in payload["confusion_matrix"]) == 100


def test_parse_artifact_captures_provenance():
    data = load(FIXTURE)
    data["prediction_files"] = {"test": "svm_tfidf_test_predictions.csv.gz"}
    payload = parse_artifact(data)
    assert payload["provenance"]["split_design_version"] == "icann-domain-disjoint-v3"
    assert payload["provenance"]["prediction_files"]["test"].endswith(".csv.gz")


def test_parse_artifact_requires_split_counts_to_cover_row_count():
    data = load(FIXTURE)
    data["row_count"] = 1001
    with pytest.raises(ArtifactError, match="split_counts"):
        parse_artifact(data)


def test_parse_artifact_rejects_fractional_support():
    data = load(FIXTURE)
    data["test_report"]["benign"]["support"] = 60.5
    with pytest.raises(ArtifactError, match="bulat"):
        parse_artifact(data)


def test_parse_artifact_accepts_integral_float_support():
    data = load(FIXTURE)
    data["test_report"]["benign"]["support"] = 60.0
    payload = parse_artifact(data)
    assert payload["report"]["test"]["benign"]["support"] == 60
    assert isinstance(payload["report"]["test"]["benign"]["support"], int)


def test_parse_artifact_rejects_matrix_row_not_matching_support():
    data = load(FIXTURE)
    # Same grand total, but the first two rows no longer match their supports.
    data["test_confusion_matrix"][0] = [49, 8, 2]
    data["test_confusion_matrix"][1] = [6, 23, 2]
    with pytest.raises(ArtifactError, match="Baris 1"):
        parse_artifact(data)


def test_parse_artifact_rejects_matrix_total_not_matching_test_split():
    data = load(FIXTURE)
    data["split_counts"]["test"] = 99
    data["row_count"] = 999
    with pytest.raises(ArtifactError, match="split_counts.test"):
        parse_artifact(data)


def test_parse_artifact_rejects_precision_not_derived_from_matrix():
    data = load(FIXTURE)
    data["test_report"]["benign"]["precision"] = 0.95
    with pytest.raises(ArtifactError, match="precision"):
        parse_artifact(data)


def test_parse_artifact_rejects_inconsistent_macro_average():
    data = load(FIXTURE)
    data["test_report"]["macro avg"]["precision"] = 0.5
    with pytest.raises(ArtifactError, match="macro avg"):
        parse_artifact(data)


@pytest.mark.parametrize(
    "mutate",
    [
        lambda data: data.update(model="logreg"),
        lambda data: data.update(representation="feature_engineering"),
        lambda data: data.update(completed=False),
        lambda data: data.update(classes=["benign"]),
        lambda data: data["test_confusion_matrix"].pop(),
        lambda data: data.update(test_confusion_matrix=[[1, 0], [0, 1]]),
        lambda data: data.update(split_counts={"train": 700}),
        lambda data: data.update(run_id="x" * 37),
    ],
)
def test_parse_artifact_rejects_invalid(mutate):
    data = load(FIXTURE)
    mutate(data)
    with pytest.raises(ArtifactError):
        parse_artifact(data)


def _dataset(row_count=100):
    return SimpleNamespace(
        id="dataset-uuid",
        filename="data.csv",
        columns=["url", "type"],
        row_count=row_count,
        uploaded_at=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )


def test_dataset_digest_changes_when_row_count_changes():
    # Report synchronisation appends a row, which must invalidate the run.
    assert dataset_digest(_dataset(100)) != dataset_digest(_dataset(101))


def test_dataset_digest_is_stable_and_null_safe():
    assert dataset_digest(_dataset(100)) == dataset_digest(_dataset(100))
    assert dataset_digest(None) is None
    assert len(dataset_digest(_dataset(100))) == 64
