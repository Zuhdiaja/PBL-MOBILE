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


class MobileUser(db.Model):
    __tablename__ = "mobile_users"
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(254), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    password_hash = db.Column(db.Text)
    google_sub = db.Column(db.String(255), unique=True)
    active = db.Column(db.Boolean, nullable=False, default=True)
    token_version = db.Column(db.Integer, nullable=False, default=1)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now)


class Dataset(db.Model):
    __tablename__ = "datasets"
    id = db.Column(db.String(36), primary_key=True)
    filename = db.Column(db.String(255), nullable=False)
    columns = db.Column(JSONB, nullable=False, default=list)
    row_count = db.Column(db.BigInteger, nullable=False, default=0)
    uploaded_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now)

    def public(self):
        return dict(id=self.id, filename=self.filename, columns=self.columns,
                    row_count=self.row_count, uploaded_at=self.uploaded_at.isoformat())


class DatasetRow(db.Model):
    __tablename__ = "dataset_rows"
    dataset_id = db.Column(db.String(36), db.ForeignKey("datasets.id", ondelete="CASCADE"), primary_key=True)
    row_number = db.Column(db.BigInteger, primary_key=True)
    values = db.Column(JSONB, nullable=False)


class DatasetState(db.Model):
    __tablename__ = "dataset_state"
    id = db.Column(db.Integer, primary_key=True)
    active_id = db.Column(db.String(36), db.ForeignKey("datasets.id", ondelete="SET NULL"))
    __table_args__ = (db.CheckConstraint("id = 1", name="single_dataset_state"),)


class ImportJob(db.Model):
    __tablename__ = "dataset_imports"
    id = db.Column(db.String(36), primary_key=True)
    filename = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(16), nullable=False, default="queued")
    row_count = db.Column(db.BigInteger, nullable=False, default=0)
    error = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now)
    updated_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now)
    __table_args__ = (
        db.Index("one_live_import", db.text("(1)"), unique=True,
                 postgresql_where=db.text("status IN ('queued', 'running')")),
        db.CheckConstraint("status IN ('queued','running','succeeded','failed')", name="import_status"),
    )

    def public(self):
        return dict(id=self.id, filename=self.filename, status=self.status,
                    row_count=self.row_count, error=self.error)


class PredictionReport(db.Model):
    __tablename__ = "prediction_reports"
    id = db.Column(db.Integer, primary_key=True)
    url = db.Column(db.String(2048), nullable=False)
    report_type = db.Column(db.String(32), nullable=False)
    reported_category = db.Column(db.String(64), nullable=False)
    status = db.Column(db.String(32), nullable=False, default="submitted")
    notes = db.Column(db.Text)
    admin_notes = db.Column(db.Text)
    reporter_email = db.Column(db.String(254))
    dataset_id = db.Column(db.String(36), db.ForeignKey("datasets.id", ondelete="SET NULL"))
    dataset_synced = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now)
    updated_at = db.Column(db.DateTime(timezone=True), nullable=False, default=now, onupdate=now)

    __table_args__ = (
        db.CheckConstraint("status IN ('submitted', 'review', 'completed', 'rejected')", name="report_status_check"),
    )

    def public(self):
        return dict(
            id=self.id,
            url=self.url,
            report_type=self.report_type,
            reported_category=self.reported_category,
            status=self.status,
            notes=self.notes,
            admin_notes=self.admin_notes,
            reporter_email=self.reporter_email,
            dataset_id=self.dataset_id,
            dataset_synced=self.dataset_synced,
            created_at=self.created_at.isoformat() if self.created_at else None,
            updated_at=self.updated_at.isoformat() if self.updated_at else None,
        )
