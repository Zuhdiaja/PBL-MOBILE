from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from io import BytesIO
from pathlib import Path
import pytest
from rq.job import Job
from rq.job import JobStatus
from app.extensions import db
from app.models import Dataset, DatasetState, DatasetRow, ImportJob, now
from app.services.importer import run_import, reconcile


def upload(client, headers, raw=b"url,label\nhttps://example.com,benign\n", name="data.csv"):
    return client.post("/api/v1/dataset/imports", data={"file":(BytesIO(raw),name)}, headers=headers)


def finish(app, response):
    assert response.status_code == 202, response.json
    job_id = response.json["import_job"]["id"]
    with app.app_context():
        run_import(job_id)
    return job_id


def test_preserve_duplicate_headers_values_and_order(app, authenticated):
    client, headers = authenticated
    raw = '\ufeffurl,label,label\r\n"https://example.com/?a=1,2"," 01 ","multi\nline"\r\n"https://example.com/?a=1,2"," 01 ","multi\nline"\r\n'.encode()
    job_id = finish(app, upload(client, headers, raw))
    meta = client.get("/api/v1/dataset").json["dataset"]
    assert meta["id"] == job_id and meta["columns"] == ["url","label","label"] and meta["row_count"] == 2
    result = client.get(f"/api/v1/dataset/rows?dataset_id={job_id}").json
    assert result["rows"] == [dict(row_number=n, values=["https://example.com/?a=1,2"," 01 ","multi\nline"]) for n in (1,2)]
    assert not Path(app.config["PRIVATE_STORAGE"], "imports", job_id).exists()


def test_replacement_and_concurrent_upload_rejected(app, authenticated):
    client, headers = authenticated
    old = finish(app, upload(client, headers))
    new = upload(client, headers, b"x,y\nnew,value\n")
    assert upload(client, headers).status_code == 409
    assert client.get("/api/v1/dataset").json["dataset"]["id"] == old
    new_id = finish(app, new)
    assert client.get("/api/v1/dataset").json["dataset"]["id"] == new_id
    assert client.get(f"/api/v1/dataset/rows?dataset_id={old}").status_code == 409
    with app.app_context():
        assert db.session.get(Dataset, old) is None


@pytest.mark.parametrize("raw", [b"a,b\nonlyone\n", b"a\n\xff\n", b'a,b\n"unclosed,value\n', b"a\nx\x00y\n", b"\n"])
def test_failed_csv_preserves_active_dataset(app, authenticated, raw):
    client, headers = authenticated
    old = finish(app, upload(client, headers))
    broken_id = finish(app, upload(client, headers, raw))
    status = client.get(f"/api/v1/dataset/imports/{broken_id}").json["import_job"]
    assert status["status"] == "failed" and status["error"]
    assert client.get("/api/v1/dataset").json["dataset"]["id"] == old
    with app.app_context():
        assert db.session.get(Dataset, broken_id) is None


def test_size_invalid_file_and_no_dataset(app, authenticated):
    client, headers = authenticated
    assert client.get("/api/v1/dataset").json["dataset"] is None
    assert client.get("/api/v1/dataset/rows?dataset_id=x").status_code == 404
    assert upload(client, headers, name="data.exe").status_code == 400
    assert upload(client, headers, raw=b"").status_code == 400
    app.config["MAX_DATASET_BYTES"] = 10
    assert upload(client, headers, raw=b"x"*11).status_code == 413
    app.config["MAX_CONTENT_LENGTH"] = 32
    assert upload(client, headers, raw=b"x"*128).status_code == 413


def test_large_stream_and_pagination(app, authenticated):
    client, headers = authenticated
    raw = ("url,label\n"+"".join(f"https://example.com/{n},0\n" for n in range(10037))).encode()
    dataset_id = finish(app, upload(client, headers, raw))
    for size in (25,50,100):
        first = client.get(f"/api/v1/dataset/rows?dataset_id={dataset_id}&page_size={size}").json
        assert len(first["rows"]) == size and first["rows"][0]["row_number"] == 1
        last = client.get(f"/api/v1/dataset/rows?dataset_id={dataset_id}&page_size={size}&page={first['page_count']}").json
        assert last["rows"][-1]["row_number"] == 10037
        assert len(last["rows"]) <= size
    for query in ("page=0", "page=-1", "page=abc", "page_size=0", "page_size=10", "page=99999999"):
        assert client.get(f"/api/v1/dataset/rows?dataset_id={dataset_id}&{query}").status_code == 400


def test_header_only_dataset(app, authenticated):
    client, headers = authenticated
    dataset_id = finish(app, upload(client, headers, b"a,b\n"))
    result = client.get(f"/api/v1/dataset/rows?dataset_id={dataset_id}").json
    assert result["rows"] == [] and result["row_count"] == 0 and result["page_count"] == 1


def test_worker_exception_cleanup(app, authenticated, monkeypatch):
    client, headers = authenticated
    old = finish(app, upload(client, headers))
    queued = upload(client, headers)
    job_id = queued.json["import_job"]["id"]
    def crash(*args):
        raise RuntimeError("simulated worker failure")
    monkeypatch.setattr("app.services.importer.save_batch", crash)
    with app.app_context(), pytest.raises(RuntimeError):
        run_import(job_id)
    assert client.get(f"/api/v1/dataset/imports/{job_id}").json["import_job"]["status"] == "failed"
    assert client.get("/api/v1/dataset").json["dataset"]["id"] == old


def test_stopped_and_stale_worker_recovery(app, authenticated):
    client, headers = authenticated
    old = finish(app, upload(client, headers))
    job_id = upload(client, headers).json["import_job"]["id"]
    with app.app_context():
        rq_job = Job.fetch(job_id, connection=app.config["SESSION_REDIS"])
        rq_job.set_status(JobStatus.FAILED)
    assert client.get(f"/api/v1/dataset/imports/{job_id}").json["import_job"]["status"] == "failed"
    next_id = upload(client, headers).json["import_job"]["id"]
    with app.app_context():
        record = db.session.get(ImportJob, next_id)
        record.updated_at = now() - timedelta(hours=2)
        db.session.commit()
    assert client.get(f"/api/v1/dataset/imports/{next_id}").json["import_job"]["status"] == "failed"
    assert client.get("/api/v1/dataset").json["dataset"]["id"] == old


def test_queue_failure_compensates(app, authenticated, monkeypatch):
    client, headers = authenticated
    def unavailable(*args, **kwargs):
        raise ConnectionError("queue unavailable")
    monkeypatch.setattr(app.extensions["queue"], "enqueue", unavailable)
    assert upload(client, headers).status_code == 503
    with app.app_context():
        assert db.session.scalar(db.select(ImportJob)).status == "failed"
        assert list(Path(app.config["PRIVATE_STORAGE"], "imports").iterdir()) == []


def test_simultaneous_uploads_database_lock(app):
    def request_upload(index):
        client = app.test_client()
        csrf = client.get("/api/v1/auth/csrf").json["csrf_token"]
        result = client.post("/api/v1/auth/login", json={"email":"admin@example.com","password":"initial-password"}, headers={"X-CSRF-Token":csrf})
        return upload(client, {"X-CSRF-Token":result.json["csrf_token"]}).status_code
    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(request_upload, range(2))) == [202, 409]
