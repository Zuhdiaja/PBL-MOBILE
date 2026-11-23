"""Report counts used by the mobile profile screen."""
from app.extensions import db
from app.models import MobileUser, PredictionReport


def _token(client, email="counts@example.com", password="password-counts-2026"):
    client.post(
        "/api/v1/mobile/auth/register",
        json={"name": "Counts", "email": email, "password": password},
    )
    response = client.post(
        "/api/v1/mobile/auth/login", json={"email": email, "password": password}
    )
    return {"Authorization": f"Bearer {response.json['token']}"}


def _report(app, owner_id, status):
    with app.app_context():
        db.session.add(
            PredictionReport(
                url="https://contoh.test/login",
                report_type="False Negative",
                reported_category="Phishing",
                status=status,
                reporter_id=owner_id,
            )
        )
        db.session.commit()


def _user_id(app, email):
    with app.app_context():
        return db.session.scalar(
            db.select(MobileUser.id).filter_by(email=email)
        )


def test_summary_counts_pending_and_total(app, client):
    headers = _token(client)
    owner = _user_id(app, "counts@example.com")
    _report(app, owner, "submitted")
    _report(app, owner, "review")
    _report(app, owner, "completed")

    response = client.get("/api/v1/mobile/reports/summary", headers=headers)

    assert response.status_code == 200
    body = response.get_json()
    assert body["total"] == 3
    assert body["pending"] == 2
    assert body["by_status"] == {"submitted": 1, "review": 1, "completed": 1}


def test_summary_only_counts_the_caller(app, client):
    headers = _token(client)
    _report(app, _user_id(app, "counts@example.com"), "completed")

    with app.app_context():
        other = MobileUser(
            name="Other", email="other@example.com", active=True
        )
        db.session.add(other)
        db.session.commit()
        other_id = other.id
    _report(app, other_id, "submitted")

    body = client.get("/api/v1/mobile/reports/summary", headers=headers).get_json()

    assert body["total"] == 1
    assert body["pending"] == 0


def test_summary_requires_a_bearer_token(client):
    assert client.get("/api/v1/mobile/reports/summary").status_code == 401
