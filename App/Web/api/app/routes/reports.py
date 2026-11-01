import math
from flask import jsonify, request
from sqlalchemy import func
from app.extensions import db, limiter
from app.models import Dataset, DatasetRow, DatasetState, PredictionReport, now
from app.routes import api, body, error

VALID_STATUSES = {"submitted", "review", "completed", "rejected"}
VALID_TYPES = {"False Positive", "False Negative"}


@api.post("/reports/submit")
@limiter.limit("30 per minute")
def reports_submit():
    data = body()
    url = data.get("url")
    report_type = data.get("type") or data.get("report_type")
    category = data.get("category") or data.get("reported_category")
    notes = data.get("notes") or ""
    email = data.get("reporter_email")

    if not isinstance(url, str) or not 1 <= len(url.strip()) <= 2048:
        return error("invalid_url", "URL laporan tidak valid.")
    if not isinstance(report_type, str) or report_type.strip() not in VALID_TYPES:
        return error("invalid_type", "Jenis laporan harus 'False Positive' atau 'False Negative'.")
    if not isinstance(category, str) or not 1 <= len(category.strip()) <= 64:
        return error("invalid_category", "Kategori laporan tidak valid.")
    if email is not None and (not isinstance(email, str) or len(email) > 254):
        return error("invalid_email", "Email pelapor tidak valid.")

    report = PredictionReport(
        url=url.strip(),
        report_type=report_type.strip(),
        reported_category=category.strip(),
        notes=notes.strip() if isinstance(notes, str) else "",
        reporter_email=email.strip().lower() if email else None,
        status="submitted",
        created_at=now(),
        updated_at=now(),
    )
    db.session.add(report)
    db.session.commit()
    return jsonify(report=report.public(), message="Laporan berhasil dikirim."), 201


@api.get("/reports")
def reports_list():
    status = request.args.get("status")
    report_type = request.args.get("type")
    search = request.args.get("search")

    try:
        page = int(request.args.get("page", 1))
        size = int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")

    if size not in (25, 50, 100):
        size = 25

    # Compute global summary
    total = db.session.scalar(db.select(func.count(PredictionReport.id))) or 0
    submitted = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "submitted")) or 0
    review = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "review")) or 0
    completed = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "completed")) or 0
    synced = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.dataset_synced.is_(True))) or 0

    query = db.select(PredictionReport)
    if status and status != "all":
        query = query.where(PredictionReport.status == status)
    if report_type and report_type != "all":
        query = query.where(PredictionReport.report_type == report_type)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.where(
            PredictionReport.url.ilike(pattern) |
            PredictionReport.notes.ilike(pattern) |
            PredictionReport.reported_category.ilike(pattern)
        )

    filtered_count = db.session.scalar(db.select(func.count()).select_from(query.subquery())) or 0
    pages = max(1, math.ceil(filtered_count / size))
    if page < 1:
        page = 1
    elif page > pages and filtered_count > 0:
        page = pages

    items = db.session.scalars(
        query.order_by(PredictionReport.created_at.desc(), PredictionReport.id.desc())
        .offset((page - 1) * size)
        .limit(size)
    ).all()

    return jsonify(
        items=[item.public() for item in items],
        page=page,
        page_size=size,
        row_count=filtered_count,
        page_count=pages,
        summary=dict(
            total=total,
            submitted=submitted,
            review=review,
            completed=completed,
            synced=synced,
        ),
    )


@api.get("/reports/<int:report_id>")
def reports_detail(report_id):
    report = db.session.get(PredictionReport, report_id)
    if not report:
        return error("not_found", "Laporan tidak ditemukan.", 404)
    return jsonify(report=report.public())


@api.patch("/reports/<int:report_id>")
def reports_update(report_id):
    report = db.session.get(PredictionReport, report_id)
    if not report:
        return error("not_found", "Laporan tidak ditemukan.", 404)

    data = body()
    status = data.get("status")
    admin_notes = data.get("admin_notes")
    category = data.get("reported_category")

    if status is not None:
        if status not in VALID_STATUSES:
            return error("invalid_status", "Status laporan tidak valid.")
        report.status = status

    if admin_notes is not None:
        report.admin_notes = admin_notes.strip() if isinstance(admin_notes, str) else ""

    if category is not None:
        if not isinstance(category, str) or not 1 <= len(category.strip()) <= 64:
            return error("invalid_category", "Kategori laporan tidak valid.")
        report.reported_category = category.strip()

    report.updated_at = now()
    db.session.commit()
    return jsonify(report=report.public(), message="Laporan berhasil diperbarui.")


@api.post("/reports/<int:report_id>/sync-dataset")
def reports_sync_dataset(report_id):
    # Lock the report so two requests for the same report cannot both sync.
    report = db.session.get(PredictionReport, report_id, with_for_update=True)
    if not report:
        return error("not_found", "Laporan tidak ditemukan.", 404)
    if report.dataset_synced:
        return error("already_synced", "Laporan ini sudah disinkronkan ke dataset.", 409)

    # Exclusive lock: this path writes Dataset.row_count, so FOR SHARE is unsafe.
    state = db.session.scalar(db.select(DatasetState).where(DatasetState.id == 1).with_for_update())
    if not state or not state.active_id:
        return error("no_active_dataset", "Belum ada dataset aktif untuk integrasi data.", 400)

    active = db.session.get(Dataset, state.active_id)
    if not active:
        return error("no_active_dataset", "Dataset aktif tidak ditemukan.", 404)

    columns = [col.lower().strip() for col in (active.columns or [])]
    url_idx = 0
    cat_idx = 1 if len(columns) > 1 else 0

    for i, col in enumerate(columns):
        if "url" in col:
            url_idx = i
        elif any(k in col for k in ("label", "category", "class", "type")):
            cat_idx = i

    values = ["" for _ in range(max(len(columns), 2))]
    if url_idx < len(values):
        values[url_idx] = report.url
    if cat_idx < len(values):
        values[cat_idx] = report.reported_category

    # Truncate or extend to match dataset column count
    if columns:
        values = values[:len(columns)]
        while len(values) < len(columns):
            values.append("")

    new_row_number = active.row_count + 1
    active.row_count = new_row_number

    row = DatasetRow(dataset_id=active.id, row_number=new_row_number, values=values)
    db.session.add(row)

    report.dataset_id = active.id
    report.dataset_synced = True
    report.status = "completed"
    report.updated_at = now()

    db.session.commit()
    return jsonify(
        report=report.public(),
        dataset_id=active.id,
        row_number=new_row_number,
        message="Laporan disetujui dan disinkronkan ke dataset aktif."
    )


@api.delete("/reports/<int:report_id>")
def reports_delete(report_id):
    report = db.session.get(PredictionReport, report_id, with_for_update=True)
    if not report:
        return error("not_found", "Laporan tidak ditemukan.", 404)
    if report.dataset_synced:
        return error(
            "report_synced",
            "Laporan sudah tersinkron ke dataset. Impor ulang dataset bila baris ini harus dihapus.",
            409,
        )

    db.session.delete(report)
    db.session.commit()
    return jsonify(message="Laporan berhasil dihapus.")
