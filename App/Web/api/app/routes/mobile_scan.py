"""URL prediction for a signed-in mobile user.

The model runs inside this service. The client only sends a URL; the category
and its margin come back together with a scan id the app can quote later.
"""
from uuid import uuid4

from flask import g, jsonify

from app.extensions import db, limiter
from app.ml.inference import InferenceUnavailable, predict
from app.models import Scan, now
from app.routes.mobile_auth import body, error, mobile, mobile_required

MAX_URL = 2048


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
