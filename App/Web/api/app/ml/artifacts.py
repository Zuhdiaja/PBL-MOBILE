"""Validation for the JSON artefact exported by the model notebook."""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

METRIC_KEYS = ("accuracy", "balanced_accuracy", "macro_f1", "weighted_f1")
REPORT_KEYS = ("precision", "recall", "f1-score", "support")
AVERAGE_KEYS = ("macro avg", "weighted avg")

# Reports are exported rounded to four decimals, so exact equality never holds.
TOLERANCE = 1e-3


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


def _support(value, field: str) -> int:
    """Support is a row count; accept 60.0 but reject 60.5."""
    number = _number(value, field)
    if number != int(number):
        raise ArtifactError(f"Field {field} harus berupa bilangan bulat.")
    return int(number)


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
            "support": _support(row.get("support"), f"{field}.{label}.support"),
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


def _check_average_rows(report: dict, classes: list[str]) -> None:
    """Recompute macro/weighted averages from the per-class rows."""
    total = sum(report[label]["support"] for label in classes)
    for key in ("precision", "recall", "f1-score"):
        macro = sum(report[label][key] for label in classes) / len(classes)
        if abs(report["macro avg"][key] - macro) > TOLERANCE:
            raise ArtifactError(f"Field macro avg.{key} tidak sesuai rata-rata kelas.")
        if total:
            weighted = sum(
                report[label][key] * report[label]["support"] for label in classes
            ) / total
            if abs(report["weighted avg"][key] - weighted) > TOLERANCE:
                raise ArtifactError(
                    f"Field weighted avg.{key} tidak sesuai bobot support kelas."
                )


def _check_matrix_rows(
    matrix: list[list[int]], report: dict, classes: list[str]
) -> None:
    """Every row sum is a class support, so a reordered matrix must be rejected."""
    for index, label in enumerate(classes):
        if sum(matrix[index]) != report[label]["support"]:
            raise ArtifactError(
                f"Baris {index + 1} test_confusion_matrix harus sama dengan support {label}."
            )


def _check_matrix_metrics(
    matrix: list[list[int]], report: dict, classes: list[str]
) -> None:
    """Precision, recall, and f1 must be derivable from the matrix itself."""
    size = len(classes)
    row_totals = [sum(row) for row in matrix]
    column_totals = [sum(matrix[row][column] for row in range(size)) for column in range(size)]
    for index, label in enumerate(classes):
        diagonal = matrix[index][index]
        recall = diagonal / row_totals[index] if row_totals[index] else 0.0
        precision = diagonal / column_totals[index] if column_totals[index] else 0.0
        f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
        for key, expected in (("precision", precision), ("recall", recall), ("f1-score", f1)):
            if abs(report[label][key] - expected) > TOLERANCE:
                raise ArtifactError(
                    f"Field test_report.{label}.{key} tidak konsisten dengan "
                    "test_confusion_matrix."
                )


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

    split_counts = _split_counts(data.get("split_counts"))
    row_count = _integer(data.get("row_count"), "row_count")
    if sum(split_counts.values()) != row_count:
        raise ArtifactError("Total split_counts harus sama dengan row_count.")
    if sum(sum(row) for row in matrix) != split_counts["test"]:
        raise ArtifactError("Total test_confusion_matrix harus sama dengan split_counts.test.")

    # A reordered or mislabelled matrix still matches the grand total, so verify
    # every row against its support before trusting the per-class numbers.
    _check_matrix_rows(matrix, test_report, classes)

    # Marking a run synthetic is an explicit declaration, never an inference from
    # a free-text note: real exports may carry a note explaining how the matrix
    # was produced. Consistency of the matrix itself is the real guard, and it
    # runs for every artefact that is not declared synthetic.
    notice = data.get("example_notice")
    synthetic = data.get("synthetic") is True
    if not synthetic:
        _check_matrix_metrics(matrix, test_report, classes)

    _check_average_rows(test_report, classes)
    if report["validation"]:
        _check_average_rows(report["validation"], classes)

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
        "split_counts": split_counts,
        "params": params,
        "preprocessing": preprocessing,
        "fit_seconds": _number(fit_seconds, "fit_seconds") if fit_seconds is not None else None,
        "input_features": _integer(input_features, "input_features") if input_features is not None else None,
        "row_count": row_count,
        "completed_at": _completed_at(data.get("completed_at_utc")),
        "provenance": {
            "split_design_version": data.get("split_design_version"),
            "prediction_files": data.get("prediction_files"),
            "example_notice": notice,
            "is_synthetic": synthetic,
        },
    }
