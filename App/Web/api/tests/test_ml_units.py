import json
from pathlib import Path

import pytest

from app.ml.artifacts import ArtifactError, parse_artifact
from app.ml.ngrams import char_ngrams
from app.ml.normalize import normalize_url

FIXTURE = Path(__file__).parent / "fixtures" / "svm_tfidf_metrics.json"


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
    payload = parse_artifact(json.loads(FIXTURE.read_text(encoding="utf-8")))
    assert payload["id"] == "test-run-000000000000000000000001"
    assert payload["classes"] == ["benign", "phishing", "malware"]
    assert payload["metrics"]["test"]["accuracy"] == 0.81
    assert sum(sum(row) for row in payload["confusion_matrix"]) == 100
    assert payload["params"]["seed"] == 42


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
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    mutate(data)
    with pytest.raises(ArtifactError):
        parse_artifact(data)
