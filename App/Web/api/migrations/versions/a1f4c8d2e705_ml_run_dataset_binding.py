"""Bind ML runs to a dataset version and keep artefact provenance.

Revision ID: a1f4c8d2e705
Revises: d91f02c437ab
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "a1f4c8d2e705"
down_revision = "d91f02c437ab"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("ml_runs", sa.Column("dataset_id", sa.String(36), nullable=True))
    op.create_foreign_key(
        "fk_ml_runs_dataset_id", "ml_runs", "datasets", ["dataset_id"], ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_ml_runs_dataset_id", "ml_runs", ["dataset_id"])
    op.add_column("ml_runs", sa.Column("dataset_sha256", sa.String(64), nullable=True))
    op.add_column(
        "ml_runs",
        sa.Column(
            "provenance",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )


def downgrade():
    op.drop_column("ml_runs", "provenance")
    op.drop_column("ml_runs", "dataset_sha256")
    op.drop_index("ix_ml_runs_dataset_id", table_name="ml_runs")
    op.drop_constraint("fk_ml_runs_dataset_id", "ml_runs", type_="foreignkey")
    op.drop_column("ml_runs", "dataset_id")
