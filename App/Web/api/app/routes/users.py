"""Authenticated account management. Mobile client authentication is not wired here."""
import math
import re
from flask import g, jsonify, request, session
from sqlalchemy.exc import IntegrityError
from werkzeug.security import generate_password_hash
from app.extensions import db, limiter
from app.models import Admin, MobileUser
from app.routes import api, body, error

MODELS = {"admin": Admin, "mobile": MobileUser}
# All admin mutations serialize membership changes, including concurrent deactivation.
ADMIN_MEMBERSHIP_LOCK = 14582544


def managed(user, kind):
    return dict(id=user.id, kind=kind, name=user.name, email=user.email,
                active=user.active, has_password=bool(user.password_hash))


def valid_email(value):
    return isinstance(value, str) and len(value) <= 254 and bool(re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", value))


def lock_admins():
    db.session.execute(db.text("SELECT pg_advisory_xact_lock(:key)"), {"key": ADMIN_MEMBERSHIP_LOCK})
    db.session.refresh(g.admin)
    if not g.admin.active or session.get("version") != g.admin.session_version:
        return error("unauthorized", "Silakan masuk kembali.", 401)


def validate_name(value):
    return isinstance(value, str) and 1 <= len(value.strip()) <= 120


@api.get("/users")
def users_list():
    kind = request.args.get("kind", "admin")
    model = MODELS.get(kind)
    if model is None:
        return error("invalid_user_kind", "Jenis akun tidak valid.")
    try:
        page = int(request.args.get("page", 1))
        size = int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")
    total = db.session.scalar(db.select(db.func.count()).select_from(model))
    pages = max(1, math.ceil(total / size)) if size in (25, 50, 100) else 0
    if page < 1 or page > pages or size not in (25, 50, 100):
        return error("invalid_pagination", "Halaman atau jumlah akun tidak valid.")
    result = db.session.scalars(db.select(model).order_by(model.id).offset((page-1)*size).limit(size)).all()
    return jsonify(kind=kind, items=[managed(user, kind) for user in result],
                   page=page, page_size=size, row_count=total, page_count=pages)


@api.post("/users/<kind>")
@limiter.limit("20 per minute")
def users_create(kind):
    model = MODELS.get(kind)
    if model is None:
        return error("not_found", "Jenis akun tidak ditemukan.", 404)
    data = body()
    name, email, password = data.get("name"), data.get("email"), data.get("password")
    if "google_allowed" in data:
        return error("unsupported_login_method", "Admin web hanya menggunakan email dan password.")
    if not validate_name(name):
        return error("invalid_name", "Nama harus 1–120 karakter.")
    if not isinstance(email, str) or not valid_email(email.strip()):
        return error("invalid_email", "Gunakan alamat email yang valid.")
    if password is not None and (not isinstance(password, str) or not 12 <= len(password) <= 256):
        return error("weak_password", "Password harus 12–256 karakter.")
    if not password:
        return error("password_required", "Password wajib diisi.")
    if kind == "admin":
        blocked = lock_admins()
        if blocked:
            return blocked
    user = model(name=name.strip(), email=email.strip().lower(), active=True,
                 password_hash=generate_password_hash(password, method="scrypt") if password else None)
    db.session.add(user)
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return error("email_exists", "Email sudah digunakan untuk jenis akun ini.", 409)
    return jsonify(user=managed(user, kind), message="Akun ditambahkan."), 201


@api.patch("/users/<kind>/<int:user_id>")
def users_update(kind, user_id):
    model = MODELS.get(kind)
    if model is None:
        return error("not_found", "Jenis akun tidak ditemukan.", 404)
    if kind == "admin":
        blocked = lock_admins()
        if blocked:
            return blocked
    user = db.session.scalar(db.select(model).where(model.id == user_id).with_for_update().execution_options(populate_existing=True))
    if user is None:
        return error("not_found", "Akun tidak ditemukan.", 404)
    data = body()
    if "email" in data and data["email"] != user.email:
        return error("email_immutable", "Email akun tidak dapat diubah.")
    name = data.get("name", user.name)
    active = data.get("active", user.active)
    if "google_allowed" in data:
        return error("unsupported_login_method", "Admin web hanya menggunakan email dan password.")
    if not validate_name(name) or not isinstance(active, bool):
        return error("invalid_user", "Nama atau status akun tidak valid.")
    if kind == "admin":
        if user.id == g.admin.id and active is False:
            return error("self_deactivation", "Anda tidak dapat menonaktifkan akun sendiri.", 409)
        if not active and user.active:
            active_count = db.session.scalar(db.select(db.func.count()).select_from(Admin).where(Admin.active.is_(True)))
            if active_count <= 1:
                return error("last_admin", "Minimal satu admin harus tetap aktif.", 409)
        if active and not user.password_hash:
            return error("password_required", "Atur password akun sebelum mengaktifkannya.", 409)
        if user.active != active:
            user.session_version += 1
    user.name, user.active = name.strip(), active
    db.session.commit()
    return jsonify(user=managed(user, kind), message="Akun diperbarui.")


@api.post("/users/<kind>/<int:user_id>/password")
@limiter.limit("5 per minute")
def users_password(kind, user_id):
    model = MODELS.get(kind)
    if model is None:
        return error("not_found", "Jenis akun tidak ditemukan.", 404)
    if kind == "admin":
        blocked = lock_admins()
        if blocked:
            return blocked
        if user_id == g.admin.id:
            return error("self_password_reset", "Ubah password akun sendiri melalui halaman Profil.", 409)
    user = db.session.scalar(db.select(model).where(model.id == user_id).with_for_update().execution_options(populate_existing=True))
    if user is None:
        return error("not_found", "Akun tidak ditemukan.", 404)
    password = body().get("password")
    if not isinstance(password, str) or not 12 <= len(password) <= 256:
        return error("weak_password", "Password baru harus 12–256 karakter.")
    user.password_hash = generate_password_hash(password, method="scrypt")
    if kind == "admin":
        user.session_version += 1
    db.session.commit()
    return jsonify(user=managed(user, kind), message="Password akun diperbarui.")
