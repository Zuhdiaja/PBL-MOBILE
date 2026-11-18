from datetime import datetime, timedelta
from pathlib import Path

from app.extensions import db
from app.ml import schedule
from app.ml.inference import predict
from app.models import Dataset, DatasetRow, DatasetState, TrainingSchedule
from app.routes import mobile_auth

NOW = datetime(2026, 11, 18, 2, 0, tzinfo=schedule.JAKARTA)


def seed_dataset(id, invalid=False):
    rows = [
        (f"https://{label}{index}.com/{label}/example-test", label)
        for label in ("benign", "phishing")
        for index in range(20)
    ]
    columns = ["url", "label"] if not invalid else ["url", "source"]
    db.session.add(Dataset(id=id, filename=f"{id}.csv", columns=columns, row_count=len(rows)))
    db.session.add_all(
        DatasetRow(dataset_id=id, row_number=n, values=list(row))
        for n, row in enumerate(rows, start=1)
    )
    state = db.session.get(DatasetState, 1) or DatasetState(id=1)
    state.active_id = id
    db.session.add(state)
    db.session.commit()


def test_scheduled_training_switches_serving_and_publishes_metrics(app, authenticated, monkeypatch):
    client, headers = authenticated
    assert client.put("/api/v1/ml/schedule", json={"enabled": True, "time": "2:00"}, headers=headers).status_code == 400
    settings = client.put("/api/v1/ml/schedule", json={"enabled": True, "time": "02:00"}, headers=headers)
    assert settings.status_code == 200
    assert settings.json["timezone"] == "Asia/Jakarta"

    with app.app_context():
        seed_dataset("first")
        schedule.run_due(NOW - timedelta(minutes=1))
        assert db.session.get(TrainingSchedule, 1).last_status is None
        schedule.run_due(NOW)
        first = predict("https://benign0.com/example")[0]
        assert first.dataset_id == "first"
        first_id = first.id
        schedule.run_due(NOW + timedelta(days=1))
    assert client.get("/api/v1/ml/schedule").json["last_status"] == "skipped"

    train = schedule.train

    def verify_old_model(rows):
        with app.app_context():
            assert predict("https://benign0.com/example")[0].id == first_id
            assert db.session.get(TrainingSchedule, 1).last_status == "running"
            schedule.run_due(NOW + timedelta(days=2))
        return train(rows)

    monkeypatch.setattr(schedule, "train", verify_old_model)
    with app.app_context():
        seed_dataset("second")
        schedule.run_due(NOW + timedelta(days=2))
        run, _, _, score = predict("https://benign0.com/benign/example-test")
        assert run.id != first_id
        assert score > 0
        assert Path(app.config["PRIVATE_STORAGE"], run.artifact_path).is_file()
        run_id = run.id
    listed = client.get("/api/v1/ml/runs").json
    assert listed["active_id"] == run_id
    detail = client.get(f"/api/v1/ml/runs/{run_id}").json["run"]
    assert detail["dataset_id"] == "second"
    assert detail["dataset_matches"] is True
    assert detail["provenance"]["source_row_count"] == 40
    assert sum(detail["split_counts"].values()) == detail["row_count"] == 40
    assert sum(map(sum, detail["confusion_matrix"])) == detail["split_counts"]["test"]
    train_counts = detail["provenance"]["train_class_counts"]
    assert set(train_counts) == set(detail["classes"])
    assert sum(train_counts.values()) == detail["split_counts"]["train"]
    for role in ("validation", "test"):
        assert sum(detail["report"][role][label]["support"] for label in detail["classes"]) == detail["split_counts"][role]


    with app.app_context():
        seed_dataset("invalid", invalid=True)
        schedule.run_due(NOW + timedelta(days=3))
        assert predict("https://benign0.com/example")[0].id == run_id
    assert client.get("/api/v1/ml/schedule").json["last_status"] == "failed"
    assert client.get(f"/api/v1/ml/runs/{run_id}").json["run"]["dataset_matches"] is False


def test_replacement_during_training_does_not_activate_stale_model(app, authenticated, monkeypatch):
    client, headers = authenticated
    assert client.put("/api/v1/ml/schedule", json={"enabled": True, "time": "02:00"}, headers=headers).status_code == 200
    train = schedule.train

    def replace_dataset(rows):
        result = train(rows)
        with app.app_context():
            seed_dataset("replacement")
            db.session.delete(db.session.get(Dataset, "training"))
            db.session.commit()
        return result

    with app.app_context():
        seed_dataset("stable")
        schedule.run_due(NOW)
        active_id = predict("benign0.com/benign")[0].id

        seed_dataset("training")
        monkeypatch.setattr(schedule, "train", replace_dataset)
        schedule.run_due(NOW + timedelta(days=1))
        assert predict("benign0.com/benign")[0].id == active_id

    settings = client.get("/api/v1/ml/schedule").json
    assert settings["last_status"] == "failed"
    assert "Dataset berubah" in settings["last_message"]
    assert settings["dataset"]["id"] == "replacement"
    assert settings["pending_dataset"] is True
    listed = client.get("/api/v1/ml/runs").json
    assert [run["id"] for run in listed["items"]] == [active_id]


def test_manual_training_uses_shared_scheduler(app, authenticated, monkeypatch):
    client, headers = authenticated

    def request_training(id):
        return client.post("/api/v1/ml/train", json={"dataset_id": id}, headers=headers)

    assert request_training("missing").status_code == 409
    with app.app_context():
        seed_dataset("first")
    queued = request_training("first")
    assert queued.status_code == 202
    assert queued.json["last_status"] == "queued"
    assert queued.json["enabled"] is False
    assert request_training("first").json["error"]["code"] == "training_busy"
    assert client.get("/api/v1/ml/runs").json["training"]["last_status"] == "queued"

    with app.app_context():
        schedule.run_due(NOW + timedelta(hours=1))
        first_id = predict("benign0.com/example")[0].id
        seed_dataset("manual-next")

    train = schedule.train

    def check_during_training(rows):
        assert request_training("manual-next").json["error"]["code"] == "training_busy"
        with app.app_context():
            assert predict("benign0.com/example")[0].id == first_id
        return train(rows)

    monkeypatch.setattr(schedule, "train", check_during_training)
    assert request_training("manual-next").status_code == 202
    assert client.put("/api/v1/ml/schedule", json={"enabled": True, "time": "02:00"}, headers=headers).status_code == 200
    with app.app_context():
        schedule.run_due(NOW + timedelta(days=1))
        schedule.run_due(NOW + timedelta(days=1))
    listed = client.get("/api/v1/ml/runs").json
    assert listed["training"]["last_status"] == "completed"
    assert listed["active_id"] != first_id
    assert len(listed["items"]) == 2
    assert request_training("manual-next").json["error"]["code"] == "no_pending_dataset"

    with app.app_context():
        schedule.run_due(NOW + timedelta(days=2))
    assert client.get("/api/v1/ml/runs").json["training"]["last_status"] == "skipped"


def test_manual_request_does_not_train_a_replacement_dataset(app, authenticated):
    client, headers = authenticated
    with app.app_context():
        seed_dataset("original")
    assert client.post("/api/v1/ml/train", json={"dataset_id": "wrong"}, headers=headers).status_code == 409
    assert client.post("/api/v1/ml/train", json={"dataset_id": "original"}, headers=headers).status_code == 202

    with app.app_context():
        seed_dataset("replacement")
        schedule.run_due(NOW)
    listed = client.get("/api/v1/ml/runs").json
    assert listed["training"]["last_status"] == "failed"
    assert "Dataset aktif telah diganti" in listed["training"]["last_message"]
    assert listed["training"]["pending_dataset"] is True
    assert listed["items"] == []


def test_schedule_is_admin_only(client):
    assert client.get("/api/v1/ml/schedule").status_code == 401
    assert client.post("/api/v1/ml/train", json={"dataset_id": "active"}).status_code == 403
    assert client.put("/api/v1/ml/schedule", json={"enabled": True, "time": "02:00"}).status_code == 403


def test_mobile_google_login_appears_in_admin_users(app, authenticated, monkeypatch):
    client, _ = authenticated
    app.config["GOOGLE_MOBILE_CLIENT_IDS"] = ["test-client"]
    monkeypatch.setattr(mobile_auth, "verify_google_id_token", lambda *_: {
        "sub": "mobile-google-subject",
        "email": "mobile-google@example.com",
        "name": "Google User",
    })
    response = client.post("/api/v1/mobile/auth/google", json={"id_token": "google-token"})
    assert response.status_code == 200
    user, = client.get("/api/v1/users?kind=mobile").json["items"]
    assert user["has_google"] is True
    assert user["has_password"] is False
    assert "google_sub" not in user
