"""Build a tiny SVM + TF-IDF pipeline for tests.

The real artefact is a 6 MB joblib file that is deliberately not committed, so
the tests train a miniature stand-in with the same shape: a char TF-IDF
vectorizer followed by a LinearSVC whose classes match the dataset.
"""
import joblib
import sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.svm import LinearSVC

CLASSES = ["benign", "phishing"]

TRAINING = [
    ("google.com", "benign"),
    ("wikipedia.org/wiki/main_page", "benign"),
    ("github.com/user/repo", "benign"),
    ("example.com/about", "benign"),
    ("paypal-login-secure.com/verify/account", "phishing"),
    ("paypal.com.secure-login.tk/update", "phishing"),
    ("verify-account-bank.com/login", "phishing"),
    ("secure-update.example.net/confirm", "phishing"),
]


def build_pipeline() -> Pipeline:
    urls = [url for url, _ in TRAINING]
    labels = [label for _, label in TRAINING]
    return Pipeline(
        steps=[
            (
                "preprocessing",
                TfidfVectorizer(
                    analyzer="char",
                    ngram_range=(3, 5),
                    lowercase=False,
                    min_df=1,
                ),
            ),
            ("classifier", LinearSVC(C=1.0, class_weight="balanced", dual=False)),
        ]
    ).fit(urls, labels)


def write_pipeline(path) -> str:
    """Save the stub pipeline to ``path`` and return its sha256."""
    import hashlib

    pipeline = build_pipeline()
    joblib.dump(pipeline, path)
    digest = hashlib.sha256(pathlib_path(path).read_bytes()).hexdigest()
    return digest


def sklearn_version() -> str:
    return sklearn.__version__


def pathlib_path(path):
    from pathlib import Path

    return path if isinstance(path, Path) else Path(path)
