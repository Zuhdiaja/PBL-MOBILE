"""Bind an ML run to the dataset version it was trained on.

An import always creates a fresh dataset id, so the id alone identifies the
version. The digest also covers the row count, which changes when a report is
synchronised into the dataset — that is what makes a run detectable as stale.
"""
from __future__ import annotations

import hashlib
import json

from app.extensions import db
from app.models import Dataset, DatasetState


def active_dataset() -> Dataset | None:
    state = db.session.get(DatasetState, 1)
    if not state or not state.active_id:
        return None
    return db.session.get(Dataset, state.active_id)


def dataset_digest(dataset: Dataset | None) -> str | None:
    if dataset is None:
        return None
    payload = {
        "id": dataset.id,
        "filename": dataset.filename,
        "columns": dataset.columns or [],
        "row_count": dataset.row_count,
        "uploaded_at": dataset.uploaded_at.isoformat() if dataset.uploaded_at else None,
    }
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()
