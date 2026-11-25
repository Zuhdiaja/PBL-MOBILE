"""Admin-only endpoints for the SVM + TF-IDF pipeline dashboard."""
from __future__ import annotations

import json
import re
from datetime import time
from flask import jsonify, request
from sqlalchemy import func, literal, or_
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import load_only
from app.extensions import db, limiter
from app.ml.artifacts import ArtifactError, parse_artifact
from app.ml.dataset_binding import active_dataset, dataset_digest
from app.ml.dataset_columns import LABEL_KEYS, column_index
from app.ml.ngrams import char_ngrams
from app.ml.normalize import normalize_url
from app.ml.inference import InferenceUnavailable, load_pipeline
from app.ml.quality import unsupported_classes_error
from app.ml.schedule import DEFAULT_TIME, pending_dataset, schedule_view
from app.ml.store import InstalledRunError, activate, lock_model_changes, upsert_run
from app.ml.url_text import model_input
from app.models import Dataset, DatasetRow, DatasetState, MLRun, TrainingSchedule
from app.routes import api, body, error

MAX_ARTIFACT_BYTES = 2 * 1024 * 1024


@api.get("/ml/schedule")
def ml_schedule():
    return jsonify(schedule_view(db.session.get(TrainingSchedule, 1), active_dataset()))


@api.put("/ml/schedule")
def ml_schedule_update():
    enabled, value = body().get("enabled"), body().get("time")
    if not isinstance(enabled, bool) or not isinstance(value, str) or not re.fullmatch(
        r"(?:[01][0-9]|2[0-3]):[0-5][0-9]", value,
    ):
        return error("invalid_schedule", "Masukkan status jadwal dan waktu WIB yang valid (JJ:MM).")
    values = {"enabled": enabled, "time": time.fromisoformat(value)}
    db.session.execute(
        insert(TrainingSchedule).values(id=1, **values)
        .on_conflict_do_update(index_elements=[TrainingSchedule.id], set_=values)
    )
    db.session.commit()
    return ml_schedule()


@api.post("/ml/train")
def ml_train():
    requested_id = body().get("dataset_id")
    if not isinstance(requested_id, str) or not 1 <= len(requested_id) <= 36:
        return error("invalid_dataset", "Pilih dataset aktif untuk training.")

    if db.session.get(TrainingSchedule, 1) is None:
        db.session.execute(
            insert(TrainingSchedule).values(id=1, enabled=False, time=DEFAULT_TIME)
            .on_conflict_do_nothing()
        )
    schedule = db.session.get(TrainingSchedule, 1, with_for_update=True, populate_existing=True)
    if schedule.requested_dataset_id or schedule.last_status == "running":
        return error("training_busy", "Training sedang mengantre atau berjalan.", 409)
    dataset = active_dataset()
    if dataset is None or dataset.id != requested_id:
        return error("dataset_changed", "Dataset aktif telah berubah. Periksa dataset terbaru.", 409)
    if not pending_dataset(dataset):
        return error("no_pending_dataset", "Dataset aktif sudah berhasil dilatih.", 409)

    schedule.requested_dataset_id = dataset.id
    response = schedule_view(schedule, dataset)
    db.session.commit()
    return jsonify(response), 202


RUNS_PAGE_SIZE = 20


def run_summaries():
    return db.select(MLRun).options(load_only(
        MLRun.id, MLRun.model, MLRun.representation, MLRun.status, MLRun.classes,
        MLRun.row_count, MLRun.input_features, MLRun.fit_seconds, MLRun.dataset_id,
        MLRun.dataset_sha256, MLRun.provenance, MLRun.artifact_sha256,
        MLRun.artifact_sklearn_version, MLRun.is_active, MLRun.completed_at,
        MLRun.created_at, MLRun.metrics,
    ))


def newest_runs(query):
    return query.order_by(
        MLRun.completed_at.desc().nulls_last(), MLRun.created_at.desc(), MLRun.id.desc(),
    )


@api.get("/ml/status")
def ml_status():
    dataset = active_dataset()
    digest = dataset_digest(dataset)
    training = schedule_view(db.session.get(TrainingSchedule, 1), dataset)
    active = db.session.scalar(run_summaries().where(MLRun.is_active.is_(True)))
    selected = active if active is not None else db.session.scalar(newest_runs(run_summaries()).limit(1))
    return jsonify(
        run=selected.public(dataset_digest=digest) if selected is not None else None,
        active_id=active.id if active is not None else None,
        dataset_sha256=digest,
        training=training,
    )


@api.get("/ml/runs")
def ml_runs():
    try:
        page = int(request.args.get("page", 1))
    except ValueError:
        page = 0
    if not 1 <= page <= 2_147_483_647 // RUNS_PAGE_SIZE:
        return error("invalid_page", "Nomor halaman riwayat model tidak valid.")
    dataset = active_dataset()
    training = schedule_view(db.session.get(TrainingSchedule, 1), dataset)
    digest = dataset_digest(dataset)
    active_id = db.session.scalar(db.select(MLRun.id).where(MLRun.is_active.is_(True)))
    runs = db.session.scalars(
        newest_runs(run_summaries()).offset((page - 1) * RUNS_PAGE_SIZE).limit(RUNS_PAGE_SIZE + 1)
    ).all()
    return jsonify(
        items=[run.public(dataset_digest=digest) for run in runs[:RUNS_PAGE_SIZE]],
        active_id=active_id,
        dataset_sha256=digest,
        training=training,
        has_next=len(runs) > RUNS_PAGE_SIZE,
    )


@api.get("/ml/runs/<run_id>")
def ml_run_detail(run_id):
    run = db.session.get(MLRun, run_id)
    if not run:
        return error("run_not_found", "Hasil model tidak ditemukan.", 404)
    return jsonify(run=run.public(detail=True, dataset_digest=dataset_digest(active_dataset())))


@api.post("/ml/runs/<run_id>/promote")
def ml_promote(run_id):
    state = db.session.get(DatasetState, 1, with_for_update={"read": True})
    lock_model_changes()
    run = db.session.get(MLRun, run_id)
    if not run:
        return error("run_not_found", "Hasil model tidak ditemukan.", 404)
    if run.is_active:
        return ml_status()
    if run.status != "awaiting_review":
        return error("promotion_unavailable", "Kandidat ini tidak dapat dipromosikan.", 409)
    dataset = db.session.get(Dataset, state.active_id) if state and state.active_id else None
    if dataset_digest(dataset) != run.dataset_sha256:
        return error("dataset_changed", "Dataset aktif sudah berubah sejak kandidat dilatih.", 409)
    issue = unsupported_classes_error(run.classes)
    if issue:
        return error("quality_failed", issue, 409)
    try:
        load_pipeline(run)
    except InferenceUnavailable as exc:
        return error("inference_unavailable", str(exc), 409)
    schedule = db.session.get(TrainingSchedule, 1, with_for_update=True)
    if schedule and schedule.last_status == "awaiting_review":
        schedule.last_status = "completed"
        schedule.last_message = "Model disetujui dan aktif untuk pemindaian."
    run.status = "completed"
    activate(run)
    db.session.commit()
    return ml_status()


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
    try:
        run = upsert_run(payload)
    except InstalledRunError as exc:
        return error("installed_run", str(exc), 409)
    return jsonify(
        run=run.public(detail=True),
        message="Hasil model diimpor.",
    ), 201


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
    label_index = column_index(columns, LABEL_KEYS)
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


def preview_url(url):
    normalized = normalize_url(url)
    text = model_input(url)
    return dict(
        model_input=text, normalized=normalized, steps=normalized["steps"],
        # N-grams must come from the model input, not from the display text.
        ngrams=char_ngrams(text),
    )


@api.get("/ml/preprocessing-examples")
def preprocessing_examples():
    dataset = active_dataset()
    if not dataset or request.args.get("dataset_id") != dataset.id:
        return error("dataset_changed", "Dataset aktif telah berubah. Muat ulang halaman.", 409)
    url_index = column_index(dataset.columns, {"url"})
    label_index = column_index(dataset.columns, LABEL_KEYS)
    if url_index is None:
        return jsonify(cleaning=None, normalization=None)

    url = DatasetRow.values[url_index].astext
    label = DatasetRow.values[label_index].astext if label_index is not None else literal(None)
    # Match Python's str.strip() for text that PostgreSQL can store.
    whitespace = (
        " \t\n\r\v\f\x1c\x1d\x1e\x1f\x85\xa0\u1680"
        "\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a"
        "\u2028\u2029\u202f\u205f\u3000"
    )
    trimmed_url = func.btrim(url, whitespace)
    trimmed_label = func.btrim(label, whitespace)
    source = (
        db.select(DatasetRow.row_number, url.label("url"), label.label("label"))
        .where(DatasetRow.dataset_id == dataset.id, trimmed_url != "")
        .order_by(DatasetRow.row_number)
    )
    cleaned = db.session.execute(
        source.where(or_(url != trimmed_url, label != func.lower(trimmed_label))).limit(1)
    ).one_or_none()
    cleaning = None
    if cleaned:
        cleaning = dict(
            row_number=cleaned.row_number,
            url=cleaned.url,
            label=cleaned.label,
            clean_url=cleaned.url.strip(),
            clean_label=cleaned.label.strip().lower() if cleaned.label is not None else None,
        )

    normalization = None
    candidates = db.session.execute(
        source.where(
            func.char_length(url) <= 2048,
            or_(
                url != trimmed_url,
                url != func.lower(url),
                trimmed_url.regexp_match(r"^(https?:|//)|^[^/?#]+\.(?:[/:?#]|$)", flags="i"),
            ),
        )
        .order_by(None)
        .order_by(url != trimmed_url, DatasetRow.row_number)
        .execution_options(yield_per=50)
    )
    with candidates:
        for row in candidates:
            result = preview_url(row.url)
            normalized = result["normalized"]
            if normalized["canonical_host"] and (
                result["model_input"] != row.url or normalized["text"] != row.url
            ):
                normalization = dict(row_number=row.row_number, preview=result)
                break
    return jsonify(cleaning=cleaning, normalization=normalization)


@api.post("/ml/preview")
@limiter.limit("30 per minute")
def ml_preview():
    url = body().get("url")
    if not isinstance(url, str) or not url.strip() or len(url) > 2048:
        return error("invalid_url", "URL harus berupa teks 1-2048 karakter.")
    return jsonify(preview_url(url))
