from flask import Flask


def create_app() -> Flask:
    return Flask(__name__, static_folder=None)
