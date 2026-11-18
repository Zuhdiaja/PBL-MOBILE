"""Persistence helper shared by the ML import endpoint and CLI."""
from __future__ import annotations

from app.extensions import db
from app.models import MLRun

FIELDS = (
    "model",
    "representation",
    "status",
    "classes",
    "metrics",
    "report",
    "confusion_matrix",
    "split_counts",
    "params",
    "preprocessing",
    "fit_seconds",
    "input_features",
    "row_count",
    "completed_at",
    "dataset_id",
    "dataset_sha256",
    "provenance",
)


class InstalledRunError(ValueError):
    """An installed pipeline and its metrics must stay paired."""


def lock_model_changes():
    db.session.execute(db.text("SELECT pg_advisory_xact_lock(14582547)"))


def activate(run):
    db.session.execute(
        db.update(MLRun).where(MLRun.is_active.is_(True)).values(is_active=False)
    )
    run.is_active = True
    db.session.add(run)


def upsert_run(payload: dict) -> MLRun:
    lock_model_changes()
    run = db.session.get(MLRun, payload["id"])
    if run is not None and run.artifact_path:
        raise InstalledRunError("Metrik model yang sudah terpasang tidak dapat ditimpa.")
    if run is None:
        run = MLRun(id=payload["id"])
        db.session.add(run)
    for field in FIELDS:
        setattr(run, field, payload.get(field))
    db.session.commit()
    return run
