"""Persist the daily model training schedule.

Revision ID: f029bd991e2a
Revises: c7d2e4b91a38
"""
from alembic import op
import sqlalchemy as sa


revision = "f029bd991e2a"
down_revision = "c7d2e4b91a38"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "training_schedule",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("time", sa.Time(), nullable=False),
        sa.Column("last_date", sa.Date()),
        sa.Column("last_status", sa.String(16)),
        sa.Column("last_message", sa.Text()),
        sa.Column("last_started_at", sa.DateTime(timezone=True)),
    )


def downgrade():
    op.drop_table("training_schedule")
