"""URL prediction for the mobile app.

Mounted on the existing ``mobile`` blueprint so the route inherits the bearer
token check, the CORS ``after_request`` hook, and the mobile rate limit. Admin
cookie sessions are never accepted here.
"""
from flask import current_app, jsonify

from app.extensions import limiter
from app.routes.mobile_auth import body, error, mobile, mobile_required
from app.services import url_model

MAX_URLS = 50
MAX_URL_LENGTH = 2048


@mobile.post("/predict")
@limiter.limit("60 per minute")
@mobile_required
def predict():
    data = body()
    urls = data.get("urls")

    if not isinstance(urls, list) or not 1 <= len(urls) <= MAX_URLS:
        return error("invalid_urls", f"Kirim 1–{MAX_URLS} URL dalam bentuk daftar.")
    for value in urls:
        if not isinstance(value, str) or not 1 <= len(value.strip()) <= MAX_URL_LENGTH:
            return error(
                "invalid_urls",
                f"Setiap URL harus berupa teks 1–{MAX_URL_LENGTH} karakter.",
            )

    # Input is validated first so a missing model cannot mask a bad request.
    if current_app.extensions.get("url_model") is None:
        return error("model_unavailable", "Model prediksi belum tersedia.", 503)

    predictions = url_model.predict(current_app, urls)
    return jsonify(predictions=predictions, model=url_model.describe(current_app))
