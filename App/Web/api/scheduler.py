from time import sleep

from app import create_app
from app.ml.schedule import run_due

if __name__ == "__main__":
    app = create_app()
    while True:
        try:
            with app.app_context():
                run_due()
        except Exception:
            app.logger.exception("Model schedule check failed")
        sleep(10)
