import math
from flask import jsonify, request
from sqlalchemy import func
from app.extensions import db, limiter
from app.models import Dataset, DatasetRow, DatasetState, PredictionReport, now
from app.routes import api, body, error

VALID_STATUSES = {"submitted", "review", "completed", "rejected"}
VALID_TYPES = {"False Positive", "False Negative"}
VALID_CATEGORIES = {"Benign", "Phishing", "Malware", "Spam", "Defacement", "Exploit"}
CATEGORY_ALIASES = {
    "aman": "Benign",
    "aman / benign": "Benign",
    "benign": "Benign",
    "phishing": "Phishing",
    "malware": "Malware",
    "spam": "Spam",
    "defacement": "Defacement",
    "exploit": "Exploit",
    "legitimate": "Benign",
}
MAX_NOTES = 2000
MAX_SEARCH = 200

# Label spellings per active dataset, keyed by (dataset id, label column index).
# Imports create a fresh dataset id, so an entry can never go stale.
_LABEL_CACHE = {}


def normalize_category(value):
    """Map a submitted label onto a canonical class name, or None."""
    return CATEGORY_ALIASES.get(value.strip().lower())


def dataset_labels(dataset_id, column_index):
    """Map lower-case label -> spelling used by this dataset."""
    key = (dataset_id, column_index)
    cached = _LABEL_CACHE.get(key)
    if cached is None:
        values = db.session.scalars(
            db.select(DatasetRow.values[column_index].astext)
            .where(DatasetRow.dataset_id == dataset_id)
            .distinct()
        ).all()
        cached = {value.lower(): value for value in values if value}
        if len(_LABEL_CACHE) > 32:
            _LABEL_CACHE.clear()
        _LABEL_CACHE[key] = cached
    return cached


@api.post("/reports/submit")
@limiter.limit("30 per minute")
def reports_submit():
    data = body()
    url = data.get("url")
    report_type = data.get("type") or data.get("report_type")
    category = data.get("category") or data.get("reported_category")
    notes = data.get("notes")
    email = data.get("reporter_email")

    if not isinstance(url, str) or not 1 <= len(url.strip()) <= 2048:
        return error("invalid_url", "URL laporan tidak valid.")
    if not isinstance(report_type, str) or report_type.strip() not in VALID_TYPES:
        return error("invalid_type", "Jenis laporan harus 'False Positive' atau 'False Negative'.")
    if not isinstance(category, str) or not 1 <= len(category.strip()) <= 64:
        return error("invalid_category", "Kategori laporan tidak valid.")
    notes = "" if notes is None else notes
    if not isinstance(notes, str):
        return error("invalid_notes", "Catatan laporan tidak valid.")
    notes = notes.strip()
    if len(notes) > MAX_NOTES:
        return error("invalid_notes", f"Catatan maksimal {MAX_NOTES} karakter.")
    if email is not None and (not isinstance(email, str) or len(email) > 254):
        return error("invalid_email", "Email pelapor tidak valid.")

    report = PredictionReport(
        url=url.strip(),
        report_type=report_type.strip(),
        reported_category=normalize_category(category) or category.strip(),
        notes=notes,
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
        return error("invalid_pagination", "Halaman atau jumlah laporan tidak valid.")

    if status and status != "all" and status not in VALID_STATUSES:
        return error("invalid_status", "Status laporan tidak valid.")
    if report_type and report_type != "all" and report_type not in VALID_TYPES:
        return error("invalid_type", "Jenis laporan tidak valid.")

    # Compute global summary
    total = db.session.scalar(db.select(func.count(PredictionReport.id))) or 0
    submitted = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "submitted")) or 0
    review = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "review")) or 0
    completed = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "completed")) or 0
    rejected = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.status == "rejected")) or 0
    synced = db.session.scalar(db.select(func.count(PredictionReport.id)).where(PredictionReport.dataset_synced.is_(True))) or 0

    query = db.select(PredictionReport)
    if status and status != "all":
        query = query.where(PredictionReport.status == status)
    if report_type and report_type != "all":
        query = query.where(PredictionReport.report_type == report_type)
    if search:
        term = search.strip()[:MAX_SEARCH]
        escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        pattern = f"%{escaped}%"
        query = query.where(
            PredictionReport.url.ilike(pattern, escape="\\") |
            PredictionReport.notes.ilike(pattern, escape="\\") |
            PredictionReport.reported_category.ilike(pattern, escape="\\")
        )

    filtered_count = db.session.scalar(db.select(func.count()).select_from(query.subquery())) or 0
    pages = max(1, math.ceil(filtered_count / size))
    # Clamp instead of rejecting: deleting the last row of a page must not error.
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
            rejected=rejected,
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
        if not isinstance(admin_notes, str):
            return error("invalid_notes", "Catatan administrator tidak valid.")
        admin_notes = admin_notes.strip()
        if len(admin_notes) > MAX_NOTES:
            return error("invalid_notes", f"Catatan maksimal {MAX_NOTES} karakter.")
        report.admin_notes = admin_notes

    if category is not None:
        if not isinstance(category, str) or not 1 <= len(category.strip()) <= 64:
            return error("invalid_category", "Kategori laporan tidak valid.")
        report.reported_category = normalize_category(category) or category.strip()

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

    # The dataset must have a URL column; guessing one silently overwrites data.
    if not any("url" in col for col in columns):
        return error("unsupported_dataset", "Dataset aktif tidak memiliki kolom URL.", 409)

    # Only canonical class names may reach the training data.
    label = normalize_category(report.reported_category)
    if not label:
        return error(
            "invalid_category",
            "Kategori laporan harus salah satu: " + ", ".join(sorted(VALID_CATEGORIES)) + ".",
            409,
        )
    if report.report_type == "False Positive" and label != "Benign":
        return error(
            "inconsistent_report",
            "Laporan 'False Positive' harus memakai kategori Benign.",
            409,
        )
    if report.report_type == "False Negative" and label == "Benign":
        return error(
            "inconsistent_report",
            "Laporan 'False Negative' tidak boleh memakai kategori Benign.",
            409,
        )

    url_idx = None
    cat_idx = None

    for i, col in enumerate(columns):
        if url_idx is None and "url" in col:
            url_idx = i
        elif cat_idx is None and any(
            k in col for k in ("label", "category", "class", "type")
        ):
            cat_idx = i

    if url_idx is None:
        return error("unsupported_dataset", "Dataset aktif tidak memiliki kolom URL.", 409)

    # Never write the label into the URL column when no label column was found.
    if cat_idx is None:
        cat_idx = next((i for i in range(len(columns)) if i != url_idx), None)
    if cat_idx is None:
        return error(
            "unsupported_dataset",
            "Dataset aktif tidak memiliki kolom kategori.",
            409,
        )

    values = ["" for _ in range(max(len(columns), 2))]
    values[url_idx] = report.url
    if cat_idx < len(values):
        # Use the spelling this dataset already uses, so no duplicate class appears.
        labels = dataset_labels(active.id, cat_idx)
        spelled = labels.get(label.lower())
        if not spelled:
            return error(
                "unsupported_dataset",
                "Dataset aktif tidak memiliki kategori " + label + ".",
                409,
            )
        values[cat_idx] = spelled

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
