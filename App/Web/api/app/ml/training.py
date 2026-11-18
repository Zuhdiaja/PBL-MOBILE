"""Fit and evaluate LinearSVC on a snapshot of the uploaded URL dataset."""
from collections import Counter
from time import monotonic
from uuid import uuid4

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import (
    accuracy_score, balanced_accuracy_score, classification_report, confusion_matrix, f1_score,
)
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline
from sklearn.svm import LinearSVC

from app.ml.artifacts import parse_artifact
from app.ml.normalize import normalize_url
from app.ml.url_text import model_input

SEED = 42
SPLIT_VERSION = "scheduled-domain-disjoint-v1"


class TrainingError(ValueError):
    """The dataset cannot safely produce a new model."""


def split_dataset(texts, labels):
    groups = []
    for text in texts:
        normalized = normalize_url(text.replace("\\", "/"))
        host = normalized["canonical_host"]
        groups.append(normalized["site"] or ".".join(host.split(".")[-2:]) or "unresolved")
    groups = np.asarray(groups)
    classes = set(labels)
    domains = {}
    for label, group in zip(labels, groups):
        domains.setdefault(label, set()).add(group)
    if len(classes) < 2 or any(len(sites) < 3 for sites in domains.values()):
        raise TrainingError("Training memerlukan minimal dua kelas, masing-masing dengan tiga grup domain berbeda.")

    outer = GroupShuffleSplit(n_splits=24, test_size=0.3, random_state=SEED)
    inner = GroupShuffleSplit(n_splits=4, test_size=0.5, random_state=SEED)
    for train, held_out in outer.split(texts, groups=groups):
        if set(labels[train]) != classes:
            continue
        for validation, test in inner.split(texts[held_out], groups=groups[held_out]):
            validation, test = held_out[validation], held_out[test]
            if set(labels[validation]) == set(labels[test]) == classes:
                return {"train": train, "validation": validation, "test": test}
    raise TrainingError("Kelas tidak dapat diwakili di semua partisi tanpa berbagi grup domain.")


def train(rows):
    unique = {}
    for raw_url, raw_label in rows:
        url = model_input(raw_url)
        label = (raw_label or "").strip().lower()
        if not url or not 1 <= len(label) <= 32:
            raise TrainingError("Dataset berisi URL kosong atau label di luar batas 1–32 karakter.")
        if label in {"accuracy", "macro avg", "weighted avg", "micro avg"}:
            raise TrainingError("Dataset memakai nama label yang dicadangkan untuk laporan evaluasi.")
        if unique.setdefault(url, label) != label:
            raise TrainingError("Ada URL yang sama dengan label berbeda setelah preprocessing.")
    if not 2 <= len(set(unique.values())) <= 50:
        raise TrainingError("Dataset training harus memuat 2–50 kelas.")

    texts = np.asarray(list(unique), dtype=object)
    labels = np.asarray(list(unique.values()))
    del unique
    split = split_dataset(texts, labels)
    vectorizer = TfidfVectorizer(
        analyzer="char", ngram_range=(3, 5), lowercase=False, min_df=2,
        max_features=75000, sublinear_tf=True, dtype=np.float32,
    )
    classifier = LinearSVC(class_weight="balanced", dual=False, max_iter=10000, random_state=SEED)
    pipeline = Pipeline([("tfidf", vectorizer), ("classifier", classifier)])
    start = monotonic()
    try:
        pipeline.fit(texts[split["train"]], labels[split["train"]])
    except ValueError as exc:
        raise TrainingError("Teks URL pada partisi training tidak menghasilkan fitur TF-IDF yang cukup.") from exc
    fit_seconds = monotonic() - start
    classes = classifier.classes_.tolist()
    train_counts = Counter(labels[split["train"]])

    artifact = {
        "run_id": uuid4().hex, "model": "svm", "representation": "tfidf", "completed": True,
        "classes": classes, "row_count": len(texts), "fit_seconds": fit_seconds,
        "input_features": len(vectorizer.vocabulary_), "classifier_settings": classifier.get_params(),
        "seed": SEED, "preprocessing": repr(vectorizer), "split_design_version": SPLIT_VERSION,
        "split_counts": {role: len(indices) for role, indices in split.items()},
        "train_class_counts": {label: train_counts[label] for label in classes},
    }
    for role in ("validation", "test"):
        indices = split[role]
        actual = labels[indices]
        predicted = pipeline.predict(texts[indices])
        artifact[role] = {
            "accuracy": accuracy_score(actual, predicted),
            "balanced_accuracy": balanced_accuracy_score(actual, predicted),
            "macro_f1": f1_score(actual, predicted, average="macro", zero_division=0),
            "weighted_f1": f1_score(actual, predicted, average="weighted", zero_division=0),
        }
        artifact[f"{role}_report"] = classification_report(
            actual, predicted, labels=classes, output_dict=True, zero_division=0,
        )
        if role == "test":
            artifact["test_confusion_matrix"] = confusion_matrix(actual, predicted, labels=classes).tolist()
    return pipeline, parse_artifact(artifact)
