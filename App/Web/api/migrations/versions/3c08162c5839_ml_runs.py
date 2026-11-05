"""ML run metrics imported from the notebook artefact.

Revision ID: 3c08162c5839
Revises: 8c41d7e21190
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "3c08162c5839"
down_revision = "8c41d7e21190"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "ml_runs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("model", sa.String(32), nullable=False),
        sa.Column("representation", sa.String(32), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="completed"),
        sa.Column("classes", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("metrics", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("report", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("confusion_matrix", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("split_counts", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("params", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("preprocessing", sa.Text(), nullable=True),
        sa.Column("fit_seconds", sa.Float(), nullable=True),
        sa.Column("input_features", sa.Integer(), nullable=True),
        sa.Column("row_count", sa.BigInteger(), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
    )
    op.create_index("ml_runs_completed_at", "ml_runs", ["completed_at"])


def downgrade():
    op.drop_index("ml_runs_completed_at", table_name="ml_runs")
    op.drop_table("ml_runs")
