"""Admin-only endpoints for the SVM + TF-IDF pipeline dashboard."""
from __future__ import annotations

import json
from flask import jsonify, request
from sqlalchemy import func
from app.extensions import db, limiter
from app.ml.artifacts import ArtifactError, parse_artifact
from app.ml.ngrams import char_ngrams
from app.ml.normalize import normalize_url
from app.ml.store import upsert_run
from app.models import Dataset, DatasetRow, DatasetState, MLRun
from app.routes import api, body, error

MAX_ARTIFACT_BYTES = 2 * 1024 * 1024
LABEL_KEYS = ("label", "category", "class", "type")


@api.get("/ml/runs")
def ml_runs():
    runs = db.session.scalars(
        db.select(MLRun).order_by(
            MLRun.completed_at.desc().nulls_last(),
            MLRun.created_at.desc(),
        )
    ).all()
    return jsonify(items=[run.public() for run in runs],
                   active_id=runs[0].id if runs else None)


@api.get("/ml/runs/<run_id>")
def ml_run_detail(run_id):
    run = db.session.get(MLRun, run_id)
    if not run:
        return error("run_not_found", "Hasil model tidak ditemukan.", 404)
    return jsonify(run=run.public(detail=True))


@api.post("/ml/runs/import")
def ml_import():
    upload = request.files.get("file")
    if not upload or not upload.filename or not upload.filename.lower().endswith(".json"):
        return error("invalid_file", "Pilih file JSON hasil model.")
    raw = upload.stream.read(MAX_ARTIFACT_BYTES + 1)
    if len(raw) > MAX_ARTIFACT_BYTES:
        return error("file_too_large", "File hasil model maksimal 2 MB.", 413)
    if not raw:
        return error("invalid_artifact", "File hasil model kosong.")
    try:
        data = json.loads(raw.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return error("invalid_artifact", "File bukan JSON yang valid.")
    try:
        payload = parse_artifact(data)
    except ArtifactError as exc:
        return error("invalid_artifact", str(exc))
    run = upsert_run(payload)
    return jsonify(run=run.public(detail=True), message="Hasil model diimpor."), 201


@api.get("/ml/dataset-summary")
def ml_dataset_summary():
    # Keep the active dataset alive while rows are grouped, like /dataset/rows.
    state = db.session.scalar(
        db.select(DatasetState).where(DatasetState.id == 1).with_for_update(read=True)
    )
    if not state or not state.active_id:
        return error("no_dataset", "Belum ada dataset aktif.", 404)
    active = db.session.get(Dataset, state.active_id)
    if not active:
        return error("no_dataset", "Dataset aktif tidak ditemukan.", 404)

    columns = active.columns or []
    label_index = next(
        (index for index, column in enumerate(columns)
         if isinstance(column, str) and any(key in column.lower() for key in LABEL_KEYS)),
        None,
    )
    if label_index is None:
        return jsonify(dataset=active.public(), class_counts=[], label_column=None)

    # label_index is a validated integer, never user input interpolated into SQL.
    label = DatasetRow.values[label_index].astext
    rows = db.session.execute(
        db.select(label.label("label"), func.count().label("count"))
        .where(DatasetRow.dataset_id == active.id)
        .group_by(label)
        .order_by(func.count().desc(), label.asc())
    ).all()
    return jsonify(
        dataset=active.public(),
        label_column=columns[label_index],
        class_counts=[{"label": row.label, "count": int(row.count)} for row in rows],
    )


@api.post("/ml/preview")
@limiter.limit("30 per minute")
def ml_preview():
    url = body().get("url")
    if not isinstance(url, str) or not url.strip() or len(url) > 2048:
        return error("invalid_url", "URL harus berupa teks 1-2048 karakter.")
    normalized = normalize_url(url)
    return jsonify(
        normalized=normalized,
        steps=normalized["steps"],
        ngrams=char_ngrams(normalized["text"]),
    )
