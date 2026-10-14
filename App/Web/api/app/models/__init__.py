from datetime import datetime, timezone
from sqlalchemy.dialects.postgresql import JSONB
from app.extensions import db


def now():
    return datetime.now(timezone.utc)


class Admin(db.Model):
    __tablename__ = "admins"
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(254), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    password_hash = db.Column(db.Text)
    google_allowed = db.Column(db.Boolean, nullable=False, default=False)
    google_sub = db.Column(db.String(255), unique=True)
    active = db.Column(db.Boolean, nullable=False, default=True)
    session_version = db.Column(db.Integer, nullable=False, default=1)
    avatar = db.Column(db.String(64))

    def public(self):
        return dict(id=self.id, email=self.email, name=self.name,
                    has_password=bool(self.password_hash),
                    avatar_url=f"/api/v1/profile/avatar?v={self.avatar}" if self.avatar else None)
