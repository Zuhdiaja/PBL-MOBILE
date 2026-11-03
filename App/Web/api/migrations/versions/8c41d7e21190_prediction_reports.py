"""Prediction reports submitted by mobile users with dataset sync.

Revision ID: 8c41d7e21190
Revises: b7c1e4a90f23
"""
from alembic import op
import sqlalchemy as sa


revision = "8c41d7e21190"
down_revision = "b7c1e4a90f23"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "prediction_reports",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("url", sa.String(2048), nullable=False),
        sa.Column("report_type", sa.String(32), nullable=False),
        sa.Column("reported_category", sa.String(64), nullable=False),
        sa.Column("status", sa.String(32), nullable=False, server_default="submitted"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("admin_notes", sa.Text(), nullable=True),
        sa.Column("reporter_email", sa.String(254), nullable=True),
        sa.Column("dataset_id", sa.String(36), sa.ForeignKey("datasets.id", ondelete="SET NULL"), nullable=True),
        sa.Column("dataset_synced", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("status IN ('submitted', 'review', 'completed', 'rejected')", name="report_status_check"),
    )


def downgrade():
    op.drop_table("prediction_reports")
