"""Character n-gram frequency preview.

This mirrors the ``analyzer='char'`` tokenisation used by the notebook, but it
only shows raw substring counts. It deliberately does not claim to reproduce
TF-IDF weights.
"""
from __future__ import annotations

from collections import Counter

DEFAULT_SIZES = (3, 4, 5)
DEFAULT_LIMIT = 20


def char_ngrams(text: object, sizes: tuple[int, ...] = DEFAULT_SIZES, limit: int = DEFAULT_LIMIT) -> dict:
    value = text if isinstance(text, str) else ""
    safe_sizes = tuple(size for size in sizes if isinstance(size, int) and size > 0)
    safe_limit = max(1, min(int(limit) if isinstance(limit, int) else DEFAULT_LIMIT, 100))
    result = {}
    total = 0
    for size in safe_sizes:
        counts = Counter(
            value[index : index + size]
            for index in range(len(value) - size + 1)
        )
        total += sum(counts.values())
        result[str(size)] = [
            {"token": token, "count": count}
            for token, count in counts.most_common(safe_limit)
        ]
    return {**result, "total_tokens": total}
