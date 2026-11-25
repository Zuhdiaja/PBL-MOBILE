from ipaddress import ip_address
from socket import getaddrinfo, gaierror

from flask import current_app, request
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

db = SQLAlchemy()
migrate = Migrate()


def client_address():
    peer = get_remote_address()
    proxy = current_app.config["TRUSTED_PROXY_HOST"]
    forwarded = request.headers.get("X-LinkGuard-Client-IP")
    if proxy and forwarded:
        try:
            address = ip_address(forwarded)
            if peer in {entry[4][0] for entry in getaddrinfo(proxy, None)}:
                return str(address.ipv4_mapped or address) if address.version == 6 else str(address)
        except (ValueError, gaierror):
            pass
    return peer


limiter = Limiter(key_func=client_address, default_limits=[])
