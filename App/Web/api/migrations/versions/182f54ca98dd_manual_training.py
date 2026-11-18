"""Persist a manual training request for the active dataset.

Revision ID: 182f54ca98dd
Revises: f029bd991e2a
"""
from alembic import op
import sqlalchemy as sa


revision = "182f54ca98dd"
down_revision = "f029bd991e2a"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("training_schedule", sa.Column("requested_dataset_id", sa.String(36)))


def downgrade():
    op.drop_column("training_schedule", "requested_dataset_id")
