"""Resolve unambiguous headers shared by training, reports, and visualization."""

LABEL_KEYS = {"label", "category", "class", "type"}


def column_index(columns, names):
    matches = [index for index, column in enumerate(columns) if column.strip().lower() in names]
    return matches[0] if len(matches) == 1 else None
