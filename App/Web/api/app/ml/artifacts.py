"""Validation for the JSON artefact exported by the model notebook."""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

METRIC_KEYS = ("accuracy", "balanced_accuracy", "macro_f1", "weighted_f1")
REPORT_KEYS = ("precision", "recall", "f1-score", "support")
AVERAGE_KEYS = ("macro avg", "weighted avg")


class ArtifactError(ValueError):
    """Raised when an uploaded artefact is not a valid metrics export."""


def _number(value, field: str, minimum: float = 0.0, maximum: float | None = None) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ArtifactError(f"Field {field} harus berupa angka.")
    value = float(value)
    if value < minimum or (maximum is not None and value > maximum):
        raise ArtifactError(f"Field {field} berada di luar rentang yang diizinkan.")
    return value


def _integer(value, field: str, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise ArtifactError(f"Field {field} harus berupa bilangan bulat >= {minimum}.")
    return value


def _metrics(value, field: str) -> dict:
    if not isinstance(value, dict):
        raise ArtifactError(f"Field {field} harus berupa objek metrik.")
    return {key: _number(value.get(key), f"{field}.{key}", 0.0, 1.0) for key in METRIC_KEYS}


def _report(value, field: str, classes: list[str]) -> dict:
    if not isinstance(value, dict):
        raise ArtifactError(f"Field {field} harus berupa objek report.")
    required = classes + list(AVERAGE_KEYS)
    result = {}
    for label in required:
        row = value.get(label)
        if not isinstance(row, dict):
            raise ArtifactError(f"Field {field}.{label} tidak ditemukan.")
        result[label] = {
            "precision": _number(row.get("precision"), f"{field}.{label}.precision", 0.0, 1.0),
            "recall": _number(row.get("recall"), f"{field}.{label}.recall", 0.0, 1.0),
            "f1-score": _number(row.get("f1-score"), f"{field}.{label}.f1-score", 0.0, 1.0),
            "support": _number(row.get("support"), f"{field}.{label}.support", 0.0),
        }
    return result


def _confusion_matrix(value, field: str, size: int) -> list[list[int]]:
    if not isinstance(value, list) or len(value) != size:
        raise ArtifactError(f"Field {field} harus berupa matriks {size}x{size}.")
    matrix = []
    for row_index, row in enumerate(value):
        if not isinstance(row, list) or len(row) != size:
            raise ArtifactError(f"Baris {row_index + 1} pada {field} harus memiliki {size} kolom.")
        matrix.append([_integer(cell, f"{field}[{row_index + 1}]") for cell in row])
    return matrix


def _split_counts(value) -> dict:
    if not isinstance(value, dict):
        raise ArtifactError("Field split_counts harus berupa objek.")
    result = {}
    for key in ("train", "validation", "test"):
        result[key] = _integer(value.get(key), f"split_counts.{key}")
    return result


def _completed_at(value) -> datetime:
    if value is None:
        return datetime.now(timezone.utc)
    if not isinstance(value, str):
        raise ArtifactError("Field completed_at_utc harus berupa tanggal ISO-8601.")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ArtifactError("Field completed_at_utc bukan tanggal ISO-8601 yang valid.") from exc


def parse_artifact(data: object) -> dict:
    """Validate a metrics artefact and map it onto the ``MLRun`` columns."""
    if not isinstance(data, dict):
        raise ArtifactError("Artefak harus berupa objek JSON.")

    model = data.get("model")
    representation = data.get("representation")
    if not isinstance(model, str) or model.strip().lower() != "svm":
        raise ArtifactError("Artefak harus berasal dari model svm.")
    if not isinstance(representation, str) or representation.strip().lower() != "tfidf":
        raise ArtifactError("Artefak harus memakai representasi tfidf.")
    if data.get("completed") is not True:
        raise ArtifactError("Artefak belum selesai (completed harus true).")

    raw_classes = data.get("classes")
    if not isinstance(raw_classes, list) or not 2 <= len(raw_classes) <= 50:
        raise ArtifactError("Field classes harus berisi 2 sampai 50 kelas.")
    classes = []
    for label in raw_classes:
        if not isinstance(label, str) or not 1 <= len(label.strip()) <= 64:
            raise ArtifactError("Setiap nama kelas harus berupa teks 1-64 karakter.")
        classes.append(label.strip())
    if len(set(classes)) != len(classes):
        raise ArtifactError("Field classes tidak boleh berisi duplikat.")

    metrics = {
        "validation": _metrics(data.get("validation"), "validation"),
        "test": _metrics(data.get("test"), "test"),
    }
    test_report = _report(data.get("test_report"), "test_report", classes)
    validation_report = data.get("validation_report")
    report = {
        "validation": _report(validation_report, "validation_report", classes)
        if validation_report is not None
        else {},
        "test": test_report,
    }

    matrix = _confusion_matrix(data.get("test_confusion_matrix"), "test_confusion_matrix", len(classes))
    support_total = sum(test_report[label]["support"] for label in classes)
    if support_total and sum(sum(row) for row in matrix) != int(support_total):
        raise ArtifactError("Total test_confusion_matrix harus sama dengan total support test_report.")

    row_count = _integer(data.get("row_count"), "row_count")
    input_features = data.get("input_features")
    fit_seconds = data.get("fit_seconds")
    preprocessing = data.get("preprocessing")
    if preprocessing is not None and not isinstance(preprocessing, str):
        raise ArtifactError("Field preprocessing harus berupa teks.")

    params = data.get("classifier_settings") or {}
    if not isinstance(params, dict):
        raise ArtifactError("Field classifier_settings harus berupa objek.")
    if "seed" in data:
        params = {**params, "seed": _integer(data.get("seed"), "seed")}

    run_id = data.get("run_id")
    if run_id is not None:
        if not isinstance(run_id, str) or not 1 <= len(run_id.strip()) <= 36:
            raise ArtifactError("Field run_id harus berupa teks 1-36 karakter.")
        run_id = run_id.strip()
    else:
        run_id = uuid4().hex

    return {
        "id": run_id,
        "model": "svm",
        "representation": "tfidf",
        "status": "completed",
        "classes": classes,
        "metrics": metrics,
        "report": report,
        "confusion_matrix": matrix,
        "split_counts": _split_counts(data.get("split_counts")),
        "params": params,
        "preprocessing": preprocessing,
        "fit_seconds": _number(fit_seconds, "fit_seconds") if fit_seconds is not None else None,
        "input_features": _integer(input_features, "input_features") if input_features is not None else None,
        "row_count": row_count,
        "completed_at": _completed_at(data.get("completed_at_utc")),
    }
