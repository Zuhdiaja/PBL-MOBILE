"""Acceptance rules for models that serve the mobile classifier."""

SUPPORTED_CLASSES = {"benign", "legitimate", "phishing", "malware", "spam", "defacement", "exploit"}


def unsupported_classes_error(classes):
    unsupported = sorted(set(classes) - SUPPORTED_CLASSES)
    if unsupported:
        return "Kategori belum didukung mobile: " + ", ".join(unsupported) + "."
    return None
