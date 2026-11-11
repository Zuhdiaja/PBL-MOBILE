"""Loads the active SVM + TF-IDF pipeline and runs predictions.

The artefact is a joblib file despite its ``.pkl`` name. Loading it is only
allowed from a path the database records, never from a request, because
unpickling executes code.

A run is usable only when it is active, non-synthetic, and the artefact still
matches the checksum and the scikit-learn version recorded at import time.
"""
from __future__ import annotations

import hashlib
import threading
from pathlib import Path

import joblib
import sklearn
from flask import current_app

from app.extensions import db
from app.ml.url_text import model_input
from app.models import MLRun


class InferenceUnavailable(RuntimeError):
    """Raised when no artefact can be trusted for this request."""


_cache_lock = threading.Lock()
# run id -> (artifact_sha256, pipeline)
_cache: dict[str, tuple[str, object]] = {}


def artifact_file(run: MLRun) -> Path:
    if not run.artifact_path:
        raise InferenceUnavailable("Model belum dipasang.")
    root = Path(current_app.config["PRIVATE_STORAGE"]).resolve()
    target = (root / run.artifact_path).resolve()
    # Defence in depth: the recorded path must stay inside private storage.
    if root not in target.parents:
        raise InferenceUnavailable("Lokasi model tidak valid.")
    if not target.is_file():
        raise InferenceUnavailable("Berkas model tidak ditemukan.")
    return target


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def active_run() -> MLRun:
    run = db.session.scalar(db.select(MLRun).where(MLRun.is_active.is_(True)))
    if run is None:
        raise InferenceUnavailable("Belum ada model aktif.")
    if run.is_synthetic:
        raise InferenceUnavailable("Model contoh tidak dapat dipakai untuk prediksi.")
    return run


def load_pipeline(run: MLRun):
    """Return the cached pipeline, reloading only when the checksum changes."""
    path = artifact_file(run)
    digest = file_sha256(path)
    if run.artifact_sha256 and digest != run.artifact_sha256:
        raise InferenceUnavailable("Berkas model tidak cocok dengan catatan impor.")

    with _cache_lock:
        cached = _cache.get(run.id)
        if cached and cached[0] == digest:
            return cached[1]

        if run.artifact_sklearn_version and (
            sklearn.__version__ != run.artifact_sklearn_version
        ):
            raise InferenceUnavailable(
                "Versi scikit-learn berbeda dengan saat model diimpor."
            )

        try:
            pipeline = joblib.load(path)
        except Exception as exc:  # noqa: BLE001 - any load failure means unusable
            raise InferenceUnavailable("Model tidak dapat dimuat.") from exc

        if not hasattr(pipeline, "predict"):
            raise InferenceUnavailable("Berkas bukan pipeline yang dapat diprediksi.")

        _cache[run.id] = (digest, pipeline)
        return pipeline


def predict(url: str) -> tuple[MLRun, str, str, float]:
    """Return the run, the model input, the category, and its margin."""
    run = active_run()
    pipeline = load_pipeline(run)
    text = model_input(url)
    if not text:
        raise InferenceUnavailable("URL tidak menghasilkan teks yang dapat diprediksi.")

    try:
        category = str(pipeline.predict([text])[0])
    except Exception as exc:  # noqa: BLE001
        raise InferenceUnavailable("Prediksi gagal dijalankan.") from exc

    score = 0.0
    try:
        margins = pipeline.decision_function([text])[0]
        classes = list(pipeline.named_steps["classifier"].classes_)
        # LinearSVC has no probabilities, so report the margin of the chosen class.
        score = float(margins[classes.index(category)])
    except Exception:  # noqa: BLE001 - margin is optional context, not the answer
        score = 0.0

    return run, text, category, score


def clear_cache() -> None:
    with _cache_lock:
        _cache.clear()
