import json
import os
from datetime import timedelta
from pathlib import Path
import click
from flask import Flask, jsonify
from flask_session import Session
from redis import Redis
from rq import Queue
from werkzeug.exceptions import HTTPException
from werkzeug.security import generate_password_hash
from app.extensions import db, migrate, limiter


def create_app(config=None):
    app = Flask(__name__, static_folder=None)
    secret = os.environ.get("SECRET_KEY")
    if not secret and not (config and config.get("TESTING")):
        raise RuntimeError("Set SECRET_KEY (minimal 32 karakter) sebelum menjalankan API.")
    if secret and len(secret) < 32:
        raise RuntimeError("SECRET_KEY harus minimal 32 karakter.")
    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
    app.config.update(
        SECRET_KEY=secret or "test-only-secret-key-at-least-32-characters",
        SQLALCHEMY_DATABASE_URI=os.environ.get("DATABASE_URL", "postgresql+psycopg://linkguard:linkguard@localhost:5432/linkguard"),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        SESSION_TYPE="redis", SESSION_REDIS=Redis.from_url(redis_url),
        SESSION_KEY_PREFIX="linkguard:session:", SESSION_COOKIE_NAME="linkguard_session",
        SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax",
        SESSION_COOKIE_SECURE=os.environ.get("COOKIE_SECURE", "false").lower() == "true",
        PERMANENT_SESSION_LIFETIME=timedelta(hours=8), SESSION_REFRESH_EACH_REQUEST=False,
        MAX_CONTENT_LENGTH=int(os.environ.get("MAX_UPLOAD_MB", "512")) * 1024 * 1024 + 1024 * 1024,
        MAX_DATASET_BYTES=int(os.environ.get("MAX_UPLOAD_MB", "512")) * 1024 * 1024,
        PRIVATE_STORAGE=os.environ.get("PRIVATE_STORAGE", str(Path(app.instance_path) / "private")),
        RATELIMIT_STORAGE_URI=redis_url,
        IMPORT_TIMEOUT=3600,
        GOOGLE_MOBILE_CLIENT_IDS=[client.strip() for client in
                                  os.environ.get("GOOGLE_MOBILE_CLIENT_IDS", "").split(",")
                                  if client.strip()],
        MOBILE_TOKEN_TTL=int(os.environ.get("MOBILE_TOKEN_TTL", str(30 * 24 * 3600))),
        MOBILE_CORS_ORIGINS=[origin.strip() for origin in
                             os.environ.get("MOBILE_CORS_ORIGINS", "").split(",")
                             if origin.strip()],
    )
    if config:
        app.config.update(config)
    for folder in ("imports", "avatars"):
        Path(app.config["PRIVATE_STORAGE"], folder).mkdir(parents=True, exist_ok=True)
    db.init_app(app)
    migrate.init_app(app, db)
    Session(app)
    limiter.init_app(app)
    app.extensions["queue"] = Queue("imports", connection=app.config["SESSION_REDIS"],
                                     default_timeout=app.config["IMPORT_TIMEOUT"])
    from app.routes import api, authenticate
    from app.routes.mobile_auth import mobile
    app.register_blueprint(api, url_prefix="/api/v1")
    app.register_blueprint(mobile, url_prefix="/api/v1/mobile")
    app.before_request(authenticate)

    @app.errorhandler(HTTPException)
    def http_error(exc):
        code = {413: "file_too_large", 429: "rate_limited", 404: "not_found"}.get(exc.code, "request_error")
        message = {413: "File melebihi batas unggahan.", 429: "Terlalu banyak percobaan. Coba lagi nanti."}.get(exc.code, exc.description)
        return jsonify(error={"code": code, "message": message}), exc.code

    @app.errorhandler(Exception)
    def unexpected_error(exc):
        db.session.rollback()
        app.logger.exception("Request failed")
        return jsonify(error={"code": "internal_error", "message": "Layanan mengalami gangguan. Coba lagi."}), 500

    @app.after_request
    def headers(response):
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    @app.cli.command("create-admin")
    @click.option("--email", required=True)
    @click.option("--name", required=True)
    @click.option("--password", prompt=False, hide_input=True, default=None,
                  help="Omit to enter the password interactively.")
    def create_admin(email, name, password):
        from app.models import Admin
        email = email.strip().lower()
        if "@" not in email or len(email) > 254 or not 1 <= len(name.strip()) <= 120:
            raise click.ClickException("Email atau nama tidak valid.")
        if db.session.scalar(db.select(Admin).filter_by(email=email)):
            raise click.ClickException("Admin sudah terdaftar.")
        if password is None:
            password = click.prompt("Password", hide_input=True, confirmation_prompt=True)
        if not 12 <= len(password) <= 256:
            raise click.ClickException("Password harus 12–256 karakter.")
        db.session.add(Admin(email=email, name=name.strip(),
                             password_hash=generate_password_hash(password, method="scrypt")))
        db.session.commit()
        click.echo(f"Admin {email} dibuat.")

    @app.cli.command("ml-import")
    @click.option("--path", required=True, type=click.Path(exists=True, dir_okay=False, path_type=Path),
                  help="Path to svm_tfidf_metrics.json.")
    def ml_import(path):
        from app.ml.artifacts import ArtifactError, parse_artifact
        from app.ml.store import upsert_run
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise click.ClickException(f"File hasil model tidak dapat dibaca: {exc}")
        try:
            payload = parse_artifact(data)
        except ArtifactError as exc:
            raise click.ClickException(f"Artefak tidak valid: {exc}")
        run = upsert_run(payload)
        click.echo(run.id)

    return app
