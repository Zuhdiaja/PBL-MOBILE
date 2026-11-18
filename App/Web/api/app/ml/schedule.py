"""Run scheduled and manual training independently of API workers."""
import os
from datetime import time, timedelta, timezone
from pathlib import Path
from tempfile import NamedTemporaryFile

import joblib
import sklearn
from flask import current_app

from app.extensions import db
from app.ml.dataset_binding import dataset_digest
from app.ml.dataset_columns import LABEL_KEYS, column_index
from app.ml.inference import file_sha256
from app.ml.store import activate, lock_model_changes
from app.ml.training import TrainingError, train
from app.models import Dataset, DatasetRow, DatasetState, MLRun, TrainingSchedule, now

JAKARTA = timezone(timedelta(hours=7))
DEFAULT_TIME = time(2, 0)
SCHEDULER_LOCK = 14582546


def pending_dataset(dataset):
    if dataset is None:
        return False
    return not db.session.scalar(
        db.select(db.exists().where(
            MLRun.dataset_id == dataset.id,
            MLRun.artifact_path.is_not(None),
            MLRun.provenance["dataset_filename"].astext.is_not(None),
        ))
    )


def schedule_view(schedule, dataset):
    queued = schedule is not None and schedule.requested_dataset_id is not None
    return {
        "enabled": schedule.enabled if schedule else False,
        "time": (schedule.time if schedule else DEFAULT_TIME).isoformat(timespec="minutes"),
        "timezone": "Asia/Jakarta",
        "dataset": dataset.public() if dataset else None,
        "pending_dataset": pending_dataset(dataset),
        "last_started_at": schedule.last_started_at.isoformat() if schedule and schedule.last_started_at and not queued else None,
        "last_date": schedule.last_date.isoformat() if schedule and schedule.last_date else None,
        "last_status": "queued" if queued else (schedule.last_status if schedule else None),
        "last_message": (
            "Permintaan training menunggu scheduler." if queued else
            (schedule.last_message if schedule else None)
        ),
    }


def read_snapshot(requested_dataset_id):
    state = db.session.scalar(
        db.select(DatasetState).where(DatasetState.id == 1).with_for_update(read=True)
    )
    dataset = db.session.get(Dataset, state.active_id) if state and state.active_id else None
    if requested_dataset_id and (dataset is None or dataset.id != requested_dataset_id):
        raise TrainingError("Dataset aktif telah diganti sebelum training dimulai. Ajukan training untuk dataset terbaru.")
    if not pending_dataset(dataset):
        return None
    url = column_index(dataset.columns, {"url"})
    label = column_index(dataset.columns, LABEL_KEYS)
    if url is None or label is None:
        raise TrainingError("CSV harus memiliki satu kolom url dan satu kolom label, category, class, atau type.")
    rows = db.session.execute(
        db.select(DatasetRow.values[url].astext, DatasetRow.values[label].astext)
        .where(DatasetRow.dataset_id == dataset.id)
        .order_by(DatasetRow.row_number)
    ).all()
    return dataset.id, dataset_digest(dataset), dataset.filename, rows


def publish(dataset_id, digest, filename, rows):
    pipeline, payload = train(rows)
    root = Path(current_app.config["PRIVATE_STORAGE"])
    relative = Path("models", f"{payload['id']}.joblib")
    # Stage, reload, and verify before changing any inference metadata.
    with NamedTemporaryFile(dir=root / "models") as staged:
        joblib.dump(pipeline, staged.name, compress=3)
        candidate = joblib.load(staged.name)
        probe = next(iter(pipeline.named_steps["tfidf"].vocabulary_))
        if candidate.predict([probe]).tolist() != pipeline.predict([probe]).tolist():
            raise TrainingError("Verifikasi pipeline model baru gagal.")
        checksum = file_sha256(Path(staged.name))

        state = db.session.scalar(
            db.select(DatasetState).where(DatasetState.id == 1).with_for_update(read=True)
        )
        dataset = db.session.get(Dataset, state.active_id) if state and state.active_id else None
        if dataset_digest(dataset) != digest:
            raise TrainingError("Dataset berubah saat training. Coba lagi dengan dataset aktif.")
        lock_model_changes()
        if not pending_dataset(dataset):
            raise TrainingError("Dataset ini sudah memiliki model yang terpasang.")
        # Preserve the temporary filename for NamedTemporaryFile cleanup.
        os.link(staged.name, root / relative)

    payload["provenance"]["dataset_filename"] = filename
    payload["provenance"]["source_row_count"] = len(rows)
    run = MLRun(
        **payload, dataset_id=dataset_id, dataset_sha256=digest,
        artifact_path=relative.as_posix(), artifact_sha256=checksum,
        artifact_sklearn_version=sklearn.__version__,
    )
    activate(run)


def run_due(when=None):
    local = (when or now()).astimezone(JAKARTA)
    # This connection holds only the scheduler lock, never a training transaction.
    with db.engine.connect().execution_options(isolation_level="AUTOCOMMIT") as lock:
        if not lock.scalar(db.text("SELECT pg_try_advisory_lock(:key)"), {"key": SCHEDULER_LOCK}):
            return
        try:
            check_schedule(local)
        finally:
            try:
                db.session.rollback()
            finally:
                try:
                    lock.execute(db.text("SELECT pg_advisory_unlock(:key)"), {"key": SCHEDULER_LOCK})
                except Exception:
                    lock.invalidate()
                    raise


def check_schedule(local):
    schedule = db.session.get(TrainingSchedule, 1, with_for_update=True)
    if not schedule:
        return
    if schedule.last_status == "running":
        schedule.last_status = "failed"
        schedule.last_message = "Training terhenti sebelum aktivasi model."
    requested_dataset_id = schedule.requested_dataset_id
    scheduled = (
        schedule.enabled
        and schedule.last_date != local.date()
        and local.time().replace(second=0, microsecond=0) == schedule.time
    )
    if not requested_dataset_id and not scheduled:
        db.session.commit()
        return

    if scheduled:
        schedule.last_date = local.date()
    schedule.requested_dataset_id = None
    schedule.last_status = "running"
    schedule.last_message = None
    schedule.last_started_at = now()
    db.session.commit()

    try:
        snapshot = read_snapshot(requested_dataset_id)
        db.session.commit()
        if snapshot:
            publish(*snapshot)
            status, message = "completed", "Model baru aktif dan hasil evaluasi tersedia."
        else:
            status, message = "skipped", "Belum ada dataset unggahan baru yang siap dilatih."
    except TrainingError as exc:
        db.session.rollback()
        status, message = "failed", str(exc)
    except Exception:
        db.session.rollback()
        current_app.logger.exception("Model training failed")
        status, message = "failed", "Training gagal. Model sebelumnya tetap tersedia jika sudah terpasang."

    schedule = db.session.get(TrainingSchedule, 1, with_for_update=True)
    schedule.last_status, schedule.last_message = status, message
    db.session.commit()
