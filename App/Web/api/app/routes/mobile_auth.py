"""Authentication for the mobile app.

Mounted at ``/api/v1/mobile`` on its own blueprint so the admin cookie session
in :mod:`app.routes` is never reused here. Mobile clients authenticate with a
bearer token kept in Redis; only ``mobile_users`` rows are ever touched, so a
mobile token can never reach admin endpoints such as ``/users`` or ``/dataset``.
"""
import hashlib
import re
import secrets
from functools import wraps

from flask import Blueprint, current_app, g, jsonify, request
from sqlalchemy.exc import IntegrityError
from werkzeug.security import check_password_hash, generate_password_hash

from app.extensions import db, limiter
from app.models import MobileUser
from app.services.google_tokens import (
    GoogleTokenError,
    verify_google_access_token,
    verify_google_id_token,
)

mobile = Blueprint("mobile", __name__)

TOKEN_PREFIX = "linkguard:mobile:token:"
DUMMY_HASH = generate_password_hash("unused-constant-time-password", method="scrypt")
CORS_HEADERS = "Authorization, Content-Type, X-Requested-With"
CORS_METHODS = "GET, POST, OPTIONS"


@mobile.after_request
def cors_headers(response):
    """Allow the Flutter web build to call the API from another origin."""
    origin = request.headers.get("Origin")
    allowed = current_app.config.get("MOBILE_CORS_ORIGINS") or []
    if origin and origin in allowed:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Headers"] = CORS_HEADERS
        response.headers["Access-Control-Allow-Methods"] = CORS_METHODS
        response.headers["Access-Control-Max-Age"] = "600"
        response.headers["Vary"] = "Origin"
    return response


def error(code, message, status=400):
    return jsonify(error={"code": code, "message": message}), status


def body():
    data = request.get_json(silent=True)
    return data if isinstance(data, dict) else {}


def valid_email(value):
    return (isinstance(value, str) and len(value) <= 254
            and bool(re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", value)))


def valid_name(value):
    return isinstance(value, str) and 1 <= len(value.strip()) <= 120


def valid_password(value):
    return isinstance(value, str) and 12 <= len(value) <= 256


def public_user(user):
    return dict(id=user.id, name=user.name, email=user.email,
                has_password=bool(user.password_hash))


def _token_key(raw):
    return TOKEN_PREFIX + hashlib.sha256(raw.encode()).hexdigest()


def issue_token(user):
    raw = secrets.token_urlsafe(32)
    ttl = current_app.config["MOBILE_TOKEN_TTL"]
    current_app.config["SESSION_REDIS"].setex(
        _token_key(raw), ttl, f"{user.id}:{user.token_version}")
    return raw, ttl


def revoke_token(raw):
    current_app.config["SESSION_REDIS"].delete(_token_key(raw))


def bearer_token():
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None
    return header[len("Bearer "):].strip() or None


def mobile_required(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        raw = bearer_token()
        if raw is None:
            return error("unauthorized", "Silakan masuk kembali.", 401)
        stored = current_app.config["SESSION_REDIS"].get(_token_key(raw))
        if stored is None:
            return error("unauthorized", "Sesi sudah berakhir. Silakan masuk kembali.", 401)
        try:
            user_id, version = (int(part) for part in stored.decode().split(":", 1))
        except (AttributeError, TypeError, ValueError):
            revoke_token(raw)
            return error("unauthorized", "Sesi tidak valid. Silakan masuk kembali.", 401)
        user = db.session.get(MobileUser, user_id)
        if user is None or not user.active or user.token_version != version:
            revoke_token(raw)
            return error("unauthorized", "Sesi sudah berakhir. Silakan masuk kembali.", 401)
        g.mobile_user = user
        return view(*args, **kwargs)
    return wrapper


def signed_in(user, status=200):
    token, ttl = issue_token(user)
    return jsonify(user=public_user(user), token=token, token_type="Bearer",
                   expires_in=ttl), status


@mobile.post("/auth/register")
@limiter.limit("5 per minute; 20 per hour")
def register():
    data = body()
    name, email, password = data.get("name"), data.get("email"), data.get("password")
    if not valid_name(name):
        return error("invalid_name", "Nama harus 1–120 karakter.")
    if not valid_email((email or "").strip()):
        return error("invalid_email", "Gunakan alamat email yang valid.")
    if not valid_password(password):
        return error("weak_password", "Password harus 12–256 karakter.")
    user = MobileUser(name=name.strip(), email=email.strip().lower(), active=True,
                      password_hash=generate_password_hash(password, method="scrypt"))
    db.session.add(user)
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return error("email_exists", "Email sudah terdaftar.", 409)
    return signed_in(user, 201)


@mobile.post("/auth/login")
@limiter.limit("10 per minute; 30 per hour")
def login():
    data = body()
    email, password = data.get("email", ""), data.get("password", "")
    if not isinstance(email, str) or not isinstance(password, str) or len(password) > 256:
        return error("invalid_credentials", "Email atau password tidak sesuai.", 401)
    user = db.session.scalar(db.select(MobileUser).filter_by(email=email.strip().lower()))
    valid = check_password_hash(
        user.password_hash if user and user.password_hash else DUMMY_HASH, password)
    if not user or not user.active or not user.password_hash or not valid:
        return error("invalid_credentials", "Email atau password tidak sesuai.", 401)
    return signed_in(user)


@mobile.post("/auth/google")
@limiter.limit("10 per minute; 30 per hour")
def google():
    client_ids = current_app.config.get("GOOGLE_MOBILE_CLIENT_IDS") or []
    if not client_ids:
        return error("google_unavailable", "Login Google belum dikonfigurasi.", 503)
    data = body()
    id_token, access_token = data.get("id_token"), data.get("access_token")
    if not isinstance(id_token, str) and not isinstance(access_token, str):
        return error("invalid_google_token", "Token Google tidak valid.", 401)
    try:
        if isinstance(id_token, str):
            claims = verify_google_id_token(id_token, client_ids)
        else:
            claims = verify_google_access_token(access_token, client_ids)
    except GoogleTokenError as exc:
        return error("invalid_google_token", str(exc), 401)

    subject = str(claims["sub"]).strip()
    email = str(claims["email"]).strip().lower()
    name = claims.get("name") if valid_name(claims.get("name")) else email.split("@")[0]

    user = db.session.scalar(db.select(MobileUser).filter_by(google_sub=subject))
    if user is None:
        existing = db.session.scalar(db.select(MobileUser).filter_by(email=email))
        if existing is not None:
            if existing.google_sub and existing.google_sub != subject:
                return error("account_conflict",
                             "Email ini sudah tertaut ke akun Google lain.", 409)
            if not existing.active:
                return error("account_inactive", "Akun dinonaktifkan. Hubungi admin.", 403)
            existing.google_sub = subject
            user = existing
        else:
            user = MobileUser(email=email, name=name.strip(), google_sub=subject, active=True)
            db.session.add(user)
    elif not user.active:
        return error("account_inactive", "Akun dinonaktifkan. Hubungi admin.", 403)

    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        user = db.session.scalar(db.select(MobileUser).filter_by(google_sub=subject))
        if user is None or not user.active:
            return error("account_conflict", "Akun tidak dapat dipakai. Coba lagi.", 409)
    return signed_in(user)


@mobile.get("/auth/me")
@mobile_required
def me():
    return jsonify(user=public_user(g.mobile_user))


@mobile.post("/auth/logout")
@mobile_required
def logout():
    revoke_token(bearer_token())
    return jsonify(message="Anda telah keluar.")
