import hmac
import math
import secrets
import time
from io import BytesIO
from pathlib import Path
from uuid import uuid4
from flask import Blueprint, current_app, g, jsonify, request, send_file, session
from PIL import Image, UnidentifiedImageError
from rq import Callback
from sqlalchemy.exc import IntegrityError
from werkzeug.security import check_password_hash, generate_password_hash
from app.extensions import db, limiter
from app.models import Admin, Dataset, DatasetRow, DatasetState, ImportJob
from app.services.importer import reconcile, import_csv, import_failed

api = Blueprint("api", __name__)
PUBLIC = {"api.csrf", "api.login", "api.health", "api.reports_submit"}
DUMMY_HASH = generate_password_hash("unused-constant-time-password", method="scrypt")


def error(code, message, status=400):
    return jsonify(error={"code": code, "message": message}), status


def authenticate():
    if request.blueprint != "api":
        return
    if request.method in {"POST", "PUT", "PATCH", "DELETE"} and request.endpoint not in {"api.reports_submit"}:
        token = request.headers.get("X-CSRF-Token", "")
        if not session.get("csrf") or not hmac.compare_digest(token.encode(), session["csrf"].encode()):
            return error("csrf_invalid", "Sesi formulir kedaluwarsa. Muat ulang halaman.", 403)
    if request.endpoint in PUBLIC:
        return
    admin = db.session.get(Admin, session.get("admin_id")) if session.get("admin_id") else None
    if not admin or not admin.active or not admin.password_hash or session.get("version") != admin.session_version or time.time() - session.get("issued_at", 0) >= 8 * 3600:
        session.clear()
        return error("unauthorized", "Silakan masuk kembali.", 401)
    g.admin = admin


def establish(admin):
    current_app.session_interface.regenerate(session)
    session.clear()
    session.permanent = True
    session.update(admin_id=admin.id, version=admin.session_version,
                   issued_at=time.time(), csrf=secrets.token_urlsafe(32))


def body():
    data = request.get_json(silent=True)
    return data if isinstance(data, dict) else {}


@api.get("/health")
def health():
    db.session.execute(db.text("SELECT 1"))
    current_app.config["SESSION_REDIS"].ping()
    return jsonify(status="ok")


@api.get("/auth/csrf")
def csrf():
    session.setdefault("csrf", secrets.token_urlsafe(32))
    return jsonify(csrf_token=session["csrf"],
                   max_upload_bytes=current_app.config["MAX_DATASET_BYTES"])


@api.post("/auth/login")
@limiter.limit("10 per minute; 30 per hour")
def login():
    data = body()
    email, password = data.get("email", ""), data.get("password", "")
    if not isinstance(email, str) or not isinstance(password, str) or len(password) > 256:
        return error("invalid_credentials", "Email atau password tidak sesuai.", 401)
    admin = db.session.scalar(db.select(Admin).filter_by(email=email.strip().lower()))
    valid = check_password_hash(admin.password_hash if admin and admin.password_hash else DUMMY_HASH, password)
    if not admin or not admin.active or not admin.password_hash or not valid:
        return error("invalid_credentials", "Email atau password tidak sesuai.", 401)
    establish(admin)
    return jsonify(user=admin.public(), csrf_token=session["csrf"])


@api.get("/auth/me")
def me():
    return jsonify(user=g.admin.public(), csrf_token=session["csrf"],
                   max_upload_bytes=current_app.config["MAX_DATASET_BYTES"])


@api.post("/auth/logout")
def logout():
    session.clear()
    return jsonify(message="Anda telah keluar.")


@api.patch("/profile")
def profile():
    name = body().get("name")
    if not isinstance(name, str) or not 1 <= len(name.strip()) <= 120:
        return error("invalid_name", "Nama harus 1–120 karakter.")
    g.admin.name = name.strip()
    db.session.commit()
    return jsonify(user=g.admin.public(), message="Profil disimpan.")


@api.post("/profile/password")
@limiter.limit("5 per minute")
def password():
    data = body()
    old, new = data.get("old_password"), data.get("new_password")
    if not g.admin.password_hash:
        return error("password_unavailable", "Password akun belum diatur. Hubungi admin lain untuk mengaturnya.")
    if not isinstance(old, str) or len(old) > 256 or not check_password_hash(g.admin.password_hash, old):
        return error("invalid_password", "Password lama tidak sesuai.")
    if not isinstance(new, str) or not 12 <= len(new) <= 256:
        return error("weak_password", "Password baru harus 12–256 karakter.")
    g.admin.password_hash = generate_password_hash(new, method="scrypt")
    g.admin.session_version += 1
    db.session.commit()
    session["version"] = g.admin.session_version
    return jsonify(message="Password diubah. Sesi di perangkat lain telah diakhiri.")


@api.route("/profile/avatar", methods=["GET", "PUT"])
def avatar():
    storage = Path(current_app.config["PRIVATE_STORAGE"], "avatars")
    if request.method == "GET":
        if not g.admin.avatar:
            return error("not_found", "Foto profil belum tersedia.", 404)
        return send_file(storage / g.admin.avatar, mimetype="image/webp")
    upload = request.files.get("file")
    if not upload:
        return error("file_required", "Pilih foto profil.")
    raw = upload.stream.read(2 * 1024 * 1024 + 1)
    if len(raw) > 2 * 1024 * 1024:
        return error("file_too_large", "Foto maksimal 2 MB.", 413)
    try:
        with Image.open(BytesIO(raw)) as image:
            if image.format not in {"JPEG", "PNG", "WEBP"} or image.width * image.height > 20_000_000:
                raise ValueError()
            image.load()
            image = image.convert("RGB")
            image.thumbnail((512, 512))
            filename = f"{uuid4().hex}.webp"
            image.save(storage / filename, format="WEBP", quality=85)
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        return error("invalid_image", "Gunakan foto JPEG, PNG, atau WebP yang valid.")
    previous = g.admin.avatar
    g.admin.avatar = filename
    db.session.commit()
    if previous:
        (storage / previous).unlink(missing_ok=True)
    return jsonify(user=g.admin.public(), message="Foto profil disimpan.")


@api.get("/dataset")
def dataset():
    reconcile()
    state = db.session.scalar(db.select(DatasetState).where(DatasetState.id == 1).with_for_update(read=True))
    active = db.session.get(Dataset, state.active_id) if state and state.active_id else None
    latest = db.session.scalar(db.select(ImportJob).order_by(ImportJob.created_at.desc()).limit(1))
    return jsonify(dataset=active.public() if active else None, latest_import=latest.public() if latest else None)


@api.post("/dataset/imports")
def create_import():
    reconcile()
    upload = request.files.get("file")
    if not upload or not upload.filename or not upload.filename.lower().endswith(".csv"):
        return error("invalid_file", "Pilih file CSV UTF-8.")
    job_id = str(uuid4())
    filename = upload.filename.replace("\\", "/").split("/")[-1][:255] or "dataset.csv"
    path = Path(current_app.config["PRIVATE_STORAGE"], "imports", job_id)
    try:
        size = 0
        with path.open("wb") as destination:
            while chunk := upload.stream.read(1024 * 1024):
                size += len(chunk)
                if size > current_app.config["MAX_DATASET_BYTES"]:
                    return error("file_too_large", "File melebihi batas unggahan.", 413)
                destination.write(chunk)
        if not size:
            return error("empty_file", "File CSV kosong.")
        job = ImportJob(id=job_id, filename=filename)
        db.session.add(job)
        try:
            # PostgreSQL's partial unique index serializes concurrent imports across API processes.
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            return error("import_busy", "Impor lain sedang berlangsung. Tunggu sampai selesai.", 409)
        try:
            current_app.extensions["queue"].enqueue(import_csv, job_id, job_id=job_id,
                job_timeout=current_app.config["IMPORT_TIMEOUT"], failure_ttl=86400,
                result_ttl=86400, on_failure=Callback(import_failed))
        except Exception:
            job.status = "failed"
            job.error = "Antrean impor tidak tersedia. Coba unggah kembali."
            db.session.commit()
            return error("queue_unavailable", job.error, 503)
        return jsonify(import_job=job.public()), 202
    finally:
        existing = db.session.get(ImportJob, job_id)
        if not existing or existing.status == "failed":
            path.unlink(missing_ok=True)


@api.get("/dataset/imports/<job_id>")
def import_status(job_id):
    reconcile()
    job = db.session.get(ImportJob, job_id)
    if not job:
        return error("not_found", "Impor tidak ditemukan.", 404)
    return jsonify(import_job=job.public())


@api.get("/dataset/rows")
def rows():
    # Hold a shared state lock so activation cannot delete rows while this page is read.
    state = db.session.scalar(db.select(DatasetState).where(DatasetState.id == 1).with_for_update(read=True))
    requested = request.args.get("dataset_id")
    if not state or not state.active_id:
        return error("no_dataset", "Belum ada dataset aktif.", 404)
    if requested != state.active_id:
        return error("dataset_changed", "Dataset telah diganti. Memuat dataset terbaru.", 409)
    try:
        page, page_size = int(request.args.get("page", 1)), int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")
    active = db.session.get(Dataset, requested)
    pages = max(1, math.ceil(active.row_count / page_size)) if page_size in (25, 50, 100) else 0
    if page_size not in (25, 50, 100) or page < 1 or page > pages:
        return error("invalid_pagination", "Halaman atau jumlah baris tidak valid.")
    first = (page - 1) * page_size + 1
    result = db.session.scalars(db.select(DatasetRow).where(DatasetRow.dataset_id == requested,
        DatasetRow.row_number >= first, DatasetRow.row_number < first + page_size).order_by(DatasetRow.row_number)).all()
    return jsonify(dataset_id=requested, page=page, page_size=page_size,
        row_count=active.row_count, page_count=pages,
        rows=[dict(row_number=row.row_number, values=row.values) for row in result])


# Register account management and report endpoints on this authenticated blueprint.
from app.routes import users as _users
from app.routes import reports as _reports
from app.routes import ml as _ml
