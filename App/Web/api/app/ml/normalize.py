"""Defensive URL normalisation used by the Pipeline ML preview.

The model consumes raw URLs, but the dashboard explains how the same URL looks
after the deterministic normalisation used for the domain-disjoint split.
Nothing here can raise for user input; an unparseable value is reported through
``parse_failed`` instead.
"""
from __future__ import annotations

import ipaddress
import re
import unicodedata
from urllib.parse import unquote, urlsplit

import idna
import tldextract

KNOWN_SCHEMES = {"http", "https", "ftp", "ws", "wss"}
_SCHEME = re.compile(r"^([a-zA-Z][a-zA-Z0-9+.-]*)://")
_EXTRACTOR = tldextract.TLDExtract(
    suffix_list_urls=(),
    cache_dir=None,
    fallback_to_snapshot=True,
)


def _trim(value: str) -> str:
    """Trim whitespace and control characters at both ends."""
    start, end = 0, len(value)
    while start < end and _is_trim_char(value[start]):
        start += 1
    while end > start and _is_trim_char(value[end - 1]):
        end -= 1
    return value[start:end]


def _is_trim_char(char: str) -> bool:
    return char.isspace() or unicodedata.category(char) == "Cc"


def _raw_host(netloc: str) -> str:
    host = netloc.rsplit("@", 1)[-1]
    if host.startswith("["):
        closing = host.find("]")
        return host[1:closing] if closing > 0 else host
    return host.split(":", 1)[0]


def _canonical_host(host: str, steps: list[str]) -> str:
    trimmed = host.rstrip(".")
    if trimmed != host:
        steps.append("strip_root_dot")
        host = trimmed
    if not host:
        return ""

    if "%" in host:
        decoded = unquote(host)
        if decoded != host:
            host = decoded
            steps.append("percent_decode")

    lowered = host.lower()
    if lowered != host:
        steps.append("lowercase_host")
        host = lowered

    if ":" in host:
        # IPv6 literals are validated here; never run IDNA on them.
        try:
            address = ipaddress.ip_address(host)
            steps.append("ip_literal")
            return str(address)
        except ValueError:
            pass

    try:
        encoded = idna.encode(host, uts46=True).decode("ascii")
        if encoded != host:
            steps.append("idna")
        return encoded
    except (idna.IDNAError, UnicodeError, ValueError):
        return host


def _site(host: str, is_ip: bool) -> str:
    if not host:
        return ""
    if is_ip:
        return f"ip:{host}"
    try:
        extracted = _EXTRACTOR(host)
        if extracted.domain and extracted.suffix:
            return f"{extracted.domain}.{extracted.suffix}"
    except (ValueError, TypeError):
        pass
    return ""


def _normalized_text(
    scheme: str, host: str, path: str, query: str, fragment: str, is_ip: bool
) -> str:
    if host and is_ip and ":" in host:
        netloc = f"[{host}]"
    else:
        netloc = host
    text = f"{scheme}://{netloc}" if scheme else netloc
    text += path or ""
    if query:
        text += f"?{query}"
    if fragment:
        text += f"#{fragment}"
    return text


def normalize_url(value: object) -> dict:
    """Return a best-effort normalised view of ``value`` without raising."""
    raw = value if isinstance(value, str) else ""
    text = _trim(raw)
    steps: list[str] = []
    if text != raw:
        steps.append("trim")

    scheme = ""
    match = _SCHEME.match(text)
    if match and match.group(1).lower() in KNOWN_SCHEMES:
        original_scheme = match.group(1)
        scheme = original_scheme.lower()
        if original_scheme != scheme:
            steps.append("lowercase_scheme")
        target = text
    else:
        target = text if text.startswith(("/", "?", "#")) else f"//{text}"

    parse_failed = False
    host = ""
    path = query = fragment = ""
    try:
        parsed = urlsplit(target)
        host = _raw_host(parsed.netloc)
        path, query, fragment = parsed.path, parsed.query, parsed.fragment
    except ValueError:
        parse_failed = True

    canonical = _canonical_host(host, steps) if host else ""

    try:
        is_ip = bool(canonical) and ipaddress.ip_address(canonical) is not None
    except ValueError:
        is_ip = False
    if is_ip and "ip_literal" not in steps:
        steps.append("ip_literal")

    return {
        "raw": raw,
        "scheme": scheme,
        "host": host,
        "canonical_host": canonical,
        "site": _site(canonical, is_ip),
        "is_ip": is_ip,
        "path": path,
        "query": query,
        "fragment": fragment,
        "parse_failed": parse_failed,
        "steps": list(dict.fromkeys(steps)),
        "text": _normalized_text(scheme, canonical, path, query, fragment, is_ip),
    }
