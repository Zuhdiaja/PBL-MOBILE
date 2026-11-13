"""The exact text the trained pipeline consumes.

The dataset stores lower-case URLs without a scheme, and the notebook feeds
those raw strings to ``TfidfVectorizer(lowercase=False)``. Anything else changes
the feature distribution: the ``://`` token carries a large positive weight for
``phishing``, so pasting a full ``https://`` URL shifts a benign prediction.

This module is the single place that maps user input onto that form. It must
stay in step with the training data, not with browser semantics.
"""
from __future__ import annotations

import re

# Characters 0-32, matching ``strip(C0_SPACE)`` in the notebook.
_C0_CHARS = "".join(chr(code) for code in range(33))

# Only http and https are stripped: those are the only schemes present in the
# dataset, and the only ones whose tokens the model learned as a phishing cue.
_SCHEME_PREFIX = re.compile(r"^(https?):[ \t\r\n]*/*", re.IGNORECASE)


def _trim(value: str) -> str:
    start, end = 0, len(value)
    while start < end and value[start] in _C0_CHARS:
        start += 1
    while end > start and value[end - 1] in _C0_CHARS:
        end -= 1
    return value[start:end]


def model_input(value: object) -> str:
    """Lower-case the whole URL and drop an ``http``/``https`` prefix.

    Nothing else changes: ``www.``, percent escapes, path case, and query
    strings stay exactly as written, because the training data kept them.
    """
    text = value if isinstance(value, str) else ""
    text = _trim(text).lower()
    text = _SCHEME_PREFIX.sub("", text)
    if text.startswith("//"):
        # Protocol-relative input such as "//example.com/path".
        text = text.lstrip("/")
    return _trim(text)
