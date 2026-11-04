"""URL classification backed by the exported SVM + TF-IDF pipeline.

The artefact is produced outside this repository (Colab) and dropped into
``instance/models``. It is intentionally *not* baked into the image: the file is
git-ignored, docker-ignored, and mounted read-only at run time. A missing model
must never stop the API from booting, because every other endpoint keeps working
without it.
"""
import math
import os
from pathlib import Path

import joblib

DEFAULT_MODEL_PATH = "instance/models/svm_tfidf_pipeline.joblib"
EXPECTED_FEATURES = 75000

# Raw label -> category shown to clients. ``legitimate`` is the seventh MURL
# class and shares the "this link is safe" meaning with ``benign``.
LABEL_TO_CATEGORY = {
    "benign": "Benign",
    "legitimate": "Benign",
    "phishing": "Phishing",
    "malware": "Malware",
    "spam": "Spam",
    "defacement": "Defacement",
    "exploit": "Exploit",
}

_SCHEMES = ("https://", "http://")

# Loading the 6 MB artefact costs a few hundred milliseconds. The test suite
# builds a fresh app per test, so the pipeline is cached per (path, mtime, size)
# and only reloaded when the file on disk actually changes.
_CACHE = {}


def normalize(url):
    """Strip whitespace, lowercase, and drop a leading HTTP scheme.

    The training data is lowercase and almost never carries a scheme, so the
    same host must map to the same input regardless of how the client sent it.
    Only ``http``/``https`` are removed; ``www.`` is left alone because dropping
    it would change the host.
    """
    value = url.strip().lower()
    for scheme in _SCHEMES:
        if value.startswith(scheme):
            return value[len(scheme):]
    return value


def resolve_path(app):
    configured = os.environ.get("URL_MODEL_PATH")
    if configured:
        return Path(configured)
    return Path(app.instance_path) / "models" / "svm_tfidf_pipeline.joblib"


def load(app):
    """Return the loaded pipeline, or ``None`` when the artefact is unavailable."""
    path = resolve_path(app)
    try:
        stat = path.stat()
    except OSError:
        app.logger.warning(
            "Model prediksi tidak ditemukan di %s. Endpoint /mobile/predict "
            "akan mengembalikan 503 sampai berkas tersedia.",
            path,
        )
        return None

    key = (str(path), stat.st_mtime_ns, stat.st_size)
    cached = _CACHE.get(key)
    if cached is not None:
        return cached

    try:
        pipeline = joblib.load(path)
    except Exception:
        app.logger.exception("Model prediksi gagal dimuat dari %s", path)
        return None

    features = getattr(pipeline.named_steps.get("classifier"), "n_features_in_", None)
    if features != EXPECTED_FEATURES:
        # Chosen behaviour: warn and keep serving. A different feature count
        # usually still predicts; refusing to boot would take down the API.
        app.logger.warning(
            "Model prediksi memiliki %s fitur, diharapkan %s.",
            features,
            EXPECTED_FEATURES,
        )

    _CACHE[key] = pipeline
    return pipeline


def describe(app):
    """Metadata returned next to the predictions."""
    pipeline = app.extensions.get("url_model")
    if pipeline is None:
        return None
    classifier = pipeline.named_steps["classifier"]
    return {
        "name": "svm_tfidf",
        "classes": [str(label) for label in classifier.classes_],
        "n_features": int(classifier.n_features_in_),
    }


def _softmax(row):
    peak = max(row)
    exponents = [math.exp(value - peak) for value in row]
    total = sum(exponents)
    return [value / total for value in exponents]


def predict(app, urls):
    """Classify each URL. Raises :class:`ModelUnavailable` when no model is loaded.

    ``confidence`` is a softmax over the SVM decision values. It is a ranking
    score, **not** a calibrated probability: LinearSVC has no ``predict_proba``
    and decision values are unbounded margins, so the softmax saturates near 1.0
    for confident rows. Do not present it as a percentage likelihood.
    """
    pipeline = app.extensions.get("url_model")
    if pipeline is None:
        raise ModelUnavailable()

    inputs = [normalize(url) for url in urls]
    decision = pipeline.decision_function(inputs)
    classes = list(pipeline.named_steps["classifier"].classes_)

    results = []
    for url, row in zip(urls, decision):
        values = row.tolist() if hasattr(row, "tolist") else list(row)
        scores = _softmax(values)
        best = max(range(len(scores)), key=scores.__getitem__)
        raw_label = str(classes[best])
        results.append(
            dict(
                url=url,
                raw_label=raw_label,
                category=LABEL_TO_CATEGORY.get(raw_label, "Benign"),
                confidence=round(scores[best], 4),
            )
        )
    return results


class ModelUnavailable(Exception):
    """Raised when the prediction artefact is not loaded."""
