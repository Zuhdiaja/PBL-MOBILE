import csv
from datetime import timedelta
from pathlib import Path
from flask import current_app
from rq.job import Job
from rq.exceptions import NoSuchJobError
from sqlalchemy import delete, insert
from app.extensions import db
from app.models import Dataset, DatasetRow, DatasetState, ImportJob, now


def fail(job_id, message):
    db.session.rollback()
    job = db.session.scalar(db.select(ImportJob).where(ImportJob.id == job_id).with_for_update().execution_options(populate_existing=True))
    if job and job.status in ("queued", "running"):
        job.status, job.error, job.updated_at = "failed", message, now()
        db.session.execute(delete(Dataset).where(Dataset.id == job_id))
        db.session.commit()
        Path(current_app.config["PRIVATE_STORAGE"], "imports", job_id).unlink(missing_ok=True)
    else:
        db.session.rollback()


def reconcile():
    jobs = db.session.scalars(db.select(ImportJob).where(ImportJob.status.in_(["queued", "running"]))).all()
    for job in jobs:
        if now() - job.updated_at > timedelta(seconds=current_app.config["IMPORT_TIMEOUT"] + 120):
            fail(job.id, "Worker tidak menyelesaikan impor. Unggah kembali.")
            continue
        try:
            queued = Job.fetch(job.id, connection=current_app.config["SESSION_REDIS"])
            status = queued.get_status(refresh=True)
            if status in ("failed", "stopped", "canceled"):
                fail(job.id, "Worker terhenti. Dataset sebelumnya tetap aktif.")
        except NoSuchJobError:
            # Allow enqueue to complete after the database commit.
            if now() - job.created_at > timedelta(minutes=2):
                fail(job.id, "Pekerjaan impor hilang dari antrean. Unggah kembali.")


def import_failed(job, connection, exc_type, exc_value, traceback):
    from app import create_app
    with create_app().app_context():
        fail(job.id, "Worker gagal menyelesaikan impor. Dataset sebelumnya tetap aktif.")


def import_csv(job_id):
    from app import create_app
    with create_app().app_context():
        run_import(job_id)


def run_import(job_id):
    path = Path(current_app.config["PRIVATE_STORAGE"], "imports", job_id)
    job = db.session.get(ImportJob, job_id)
    if not job or job.status != "queued":
        return
    try:
        job.status, job.updated_at = "running", now()
        new = Dataset(id=job_id, filename=job.filename, columns=[], row_count=0, uploaded_at=job.created_at)
        db.session.add(new)
        db.session.commit()
        csv.field_size_limit(current_app.config["MAX_DATASET_BYTES"])
        with path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.reader(stream, strict=True)
            columns = next(reader, None)
            if not columns or not any(columns) or len(columns) > 1024 or any("\x00" in value for value in columns):
                raise ValueError("Header CSV tidak valid (maksimal 1024 kolom).")
            new.columns = columns
            db.session.commit()
            batch, count, batch_bytes = [], 0, 0
            for values in reader:
                if len(values) != len(columns):
                    raise ValueError(f"Baris data {count + 1} memiliki jumlah kolom yang berbeda dari header.")
                if any("\x00" in value for value in values):
                    raise ValueError(f"Baris data {count + 1} mengandung karakter NUL.")
                count += 1
                batch.append(dict(dataset_id=job_id, row_number=count, values=values))
                batch_bytes += sum(len(value) for value in values)
                if len(batch) >= 1000 or batch_bytes >= 4 * 1024 * 1024:
                    save_batch(job_id, batch, count)
                    batch, batch_bytes = [], 0
            if batch:
                save_batch(job_id, batch, count)
        # Lock the job before activation; a reconciled/failed worker can never promote its staging data.
        job = db.session.scalar(db.select(ImportJob).where(ImportJob.id == job_id).with_for_update().execution_options(populate_existing=True))
        if job.status != "running":
            db.session.rollback()
            return
        new = db.session.get(Dataset, job_id)
        new.row_count = count
        state = db.session.get(DatasetState, 1)
        previous = state.active_id if state else None
        if not state:
            state = DatasetState(id=1)
            db.session.add(state)
        state.active_id = job_id
        job.status, job.row_count, job.updated_at = "succeeded", count, now()
        db.session.flush()
        if previous:
            db.session.execute(delete(Dataset).where(Dataset.id == previous))
        db.session.commit()
    except (UnicodeError, csv.Error, ValueError) as exc:
        fail(job_id, f"CSV tidak dapat diimpor: {exc}")
    except Exception:
        current_app.logger.exception("CSV import failed")
        fail(job_id, "Impor gagal. Dataset sebelumnya tetap aktif. Coba unggah kembali.")
        raise
    finally:
        path.unlink(missing_ok=True)


def save_batch(job_id, batch, count):
    job = db.session.scalar(db.select(ImportJob).where(ImportJob.id == job_id).with_for_update().execution_options(populate_existing=True))
    if job.status != "running":
        raise ValueError("Impor telah dihentikan.")
    db.session.execute(insert(DatasetRow), batch)
    job.row_count, job.updated_at = count, now()
    db.session.commit()
