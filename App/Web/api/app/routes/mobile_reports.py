"""Reports owned by a verified mobile bearer identity, independent of admin sessions."""
import math

from flask import g, jsonify, request

from app.extensions import db, limiter
from app.models import PredictionReport
from app.routes.mobile_auth import mobile, mobile_required, error
from app.routes.reports import create_report


def mobile_report(report):
    # Internal admin notes and reporter identity are not part of the mobile API.
    data = report.public()
    for key in ("admin_notes", "reporter_email", "reporter_id", "dataset_id"):
        data.pop(key)
    return data


@mobile.post("/reports")
@limiter.limit("30 per minute")
@mobile_required
def submit_report():
    response, status = create_report(g.mobile_user)
    if status != 201:
        return response, status
    report = response.get_json()["report"]
    for key in ("admin_notes", "reporter_email", "reporter_id", "dataset_id"):
        report.pop(key)
    return jsonify(report=report, message="Laporan berhasil dikirim."), 201


@mobile.get("/reports")
@mobile_required
def list_reports():
    try:
        page = int(request.args.get("page", 1))
        size = int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")
    if page < 1 or size not in (25, 50, 100):
        return error("invalid_pagination", "Halaman atau jumlah laporan tidak valid.")
    query = db.select(PredictionReport).where(PredictionReport.reporter_id == g.mobile_user.id)
    count = db.session.scalar(db.select(db.func.count()).select_from(query.subquery())) or 0
    pages = max(1, math.ceil(count / size))
    page = min(page, pages)
    items = db.session.scalars(query.order_by(
        PredictionReport.created_at.desc(), PredictionReport.id.desc()
    ).offset((page - 1) * size).limit(size)).all()
    return jsonify(items=[mobile_report(item) for item in items], page=page,
                   page_size=size, row_count=count, page_count=pages)


@mobile.get("/reports/<int:report_id>")
@mobile_required
def report_detail(report_id):
    report = db.session.scalar(db.select(PredictionReport).where(
        PredictionReport.id == report_id, PredictionReport.reporter_id == g.mobile_user.id))
    if report is None:
        return error("not_found", "Laporan tidak ditemukan.", 404)
    return jsonify(report=mobile_report(report))
