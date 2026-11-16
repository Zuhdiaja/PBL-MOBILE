"""URL prediction for a signed-in mobile user.

The model runs inside this service. The client only sends a URL; the category
and its margin come back together with a scan id the app can quote later.
"""
import math
from uuid import uuid4

from flask import g, jsonify, request
from sqlalchemy import func

from app.extensions import db, limiter
from app.ml.inference import InferenceUnavailable, predict
from app.models import Scan, now
from app.routes.mobile_auth import body, error, mobile, mobile_required

MAX_URL = 2048
PAGE_SIZES = (25, 50, 100)
# ``legitimate`` and ``benign`` both mean "nothing harmful found"; the app keeps
# them apart on screen, but the safety counts treat them the same.
SAFE_CATEGORIES = ("benign", "legitimate")


@mobile.post("/scan")
@limiter.limit("60 per minute")
@mobile_required
def create_scan():
    url = body().get("url")
    if not isinstance(url, str) or not 1 <= len(url.strip()) <= MAX_URL:
        return error("invalid_url", "URL harus berupa teks 1-2048 karakter.")

    try:
        run, text, category, score = predict(url)
    except InferenceUnavailable as exc:
        return error("inference_unavailable", str(exc), 503)

    scan = Scan(
        id=str(uuid4()),
        mobile_user_id=g.mobile_user.id,
        url=url.strip(),
        model_input=text,
        category=category,
        score=score,
        score_kind="margin",
        model_run_id=run.id,
        created_at=now(),
    )
    db.session.add(scan)
    db.session.commit()
    return jsonify(scan=scan.public(), message="Pemindaian selesai."), 201


@mobile.get("/scans")
@mobile_required
def list_scans():
    """The caller's own scans, newest first."""
    try:
        page = int(request.args.get("page", 1))
        page_size = int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")
    if page < 1 or page_size not in PAGE_SIZES:
        return error("invalid_pagination", "Halaman atau jumlah baris tidak valid.")

    owned = db.select(Scan).where(Scan.mobile_user_id == g.mobile_user.id)
    count = db.session.scalar(db.select(func.count()).select_from(owned.subquery())) or 0
    pages = max(1, math.ceil(count / page_size))
    # Clamp like the reports list: the last row of a page may have been removed.
    page = min(page, pages)

    items = db.session.scalars(
        owned.order_by(Scan.created_at.desc(), Scan.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()
    return jsonify(
        items=[scan.public() for scan in items],
        page=page,
        page_size=page_size,
        row_count=count,
        page_count=pages,
    )


@mobile.get("/scans/summary")
@mobile_required
def scan_summary():
    """Counts used by the statistics and profile screens."""
    rows = db.session.execute(
        db.select(Scan.category, func.count())
        .where(Scan.mobile_user_id == g.mobile_user.id)
        .group_by(Scan.category)
    ).all()
    by_category = {category: int(count) for category, count in rows}
    total = sum(by_category.values())
    safe = sum(by_category.get(name, 0) for name in SAFE_CATEGORIES)
    return jsonify(
        total=total,
        safe=safe,
        unsafe=total - safe,
        by_category=by_category,
    )
