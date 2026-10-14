from redis import Redis
from rq import Worker
from app import create_app

app = create_app()
if __name__ == "__main__":
    Worker(["imports"], connection=app.config["SESSION_REDIS"]).work(with_scheduler=True)
