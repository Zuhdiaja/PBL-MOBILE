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
from app.models import Admin

api = Blueprint("api", __name__)
PUBLIC = {"api.csrf", "api.login", "api.health"}
DUMMY_HASH = generate_password_hash("unused-constant-time-password", method="scrypt")


def error(code, message, status=400):
    return jsonify(error={"code": code, "message": message}), status


def authenticate():
    if request.blueprint != "api":
        return
    if request.method in {"POST", "PUT", "PATCH", "DELETE"}:
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
