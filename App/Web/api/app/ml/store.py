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
)


def upsert_run(payload: dict) -> MLRun:
    run = db.session.get(MLRun, payload["id"])
    if run is None:
        run = MLRun(id=payload["id"])
        db.session.add(run)
    for field in FIELDS:
        setattr(run, field, payload.get(field))
    db.session.commit()
    return run
