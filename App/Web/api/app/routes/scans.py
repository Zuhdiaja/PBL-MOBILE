"""Admin view of every URL scanned from the mobile app.

Read-only: scans are created by the mobile endpoint and are an audit trail, so
nothing here mutates them. The owner of each scan is included because that is
what distinguishes this view from the mobile history.
"""
import math

from flask import jsonify, request
from sqlalchemy import func

from app.extensions import db
from app.models import MobileUser, Scan
from app.routes import api, error

PAGE_SIZES = (25, 50, 100)
MAX_SEARCH = 200
SAFE_CATEGORIES = ("benign", "legitimate")


def scan_public(scan, user):
    """A scan plus the account that submitted it."""
    data = scan.public()
    data["user"] = dict(
        id=user.id,
        name=user.name,
        email=user.email,
        active=user.active,
    )
    return data


@api.get("/scans")
def scans_list():
    category = request.args.get("category")
    search = request.args.get("search")

    try:
        page = int(request.args.get("page", 1))
        size = int(request.args.get("page_size", 25))
    except ValueError:
        return error("invalid_pagination", "Halaman tidak valid.")
    if size not in PAGE_SIZES:
        return error("invalid_pagination", "Halaman atau jumlah baris tidak valid.")

    query = db.select(Scan, MobileUser).join(MobileUser, MobileUser.id == Scan.mobile_user_id)
    if category and category != "all":
        query = query.where(func.lower(Scan.category) == category.strip().lower())
    if search:
        term = search.strip()[:MAX_SEARCH]
        escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        pattern = f"%{escaped}%"
        query = query.where(
            Scan.url.ilike(pattern, escape="\\")
            | MobileUser.email.ilike(pattern, escape="\\")
            | MobileUser.name.ilike(pattern, escape="\\")
        )

    filtered = db.session.scalar(db.select(func.count()).select_from(query.subquery())) or 0
    pages = max(1, math.ceil(filtered / size))
    # Clamp like the reports list: the last row of a page may have been removed.
    page = min(max(page, 1), pages)

    rows = db.session.execute(
        query.order_by(Scan.created_at.desc(), Scan.id.desc())
        .offset((page - 1) * size)
        .limit(size)
    ).all()

    return jsonify(
        items=[scan_public(scan, user) for scan, user in rows],
        page=page,
        page_size=size,
        row_count=filtered,
        page_count=pages,
    )


@api.get("/scans/summary")
def scans_summary():
    total = db.session.scalar(db.select(func.count(Scan.id))) or 0
    rows = db.session.execute(
        db.select(Scan.category, func.count()).group_by(Scan.category)
    ).all()
    by_category = {category: int(count) for category, count in rows}
    safe = sum(by_category.get(name, 0) for name in SAFE_CATEGORIES)
    users = db.session.scalar(db.select(func.count(func.distinct(Scan.mobile_user_id)))) or 0
    return jsonify(
        total=total,
        safe=safe,
        unsafe=total - safe,
        users=users,
        by_category=by_category,
    )
