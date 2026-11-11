"""Store the trained pipeline and the scans it produces.

Revision ID: c7d2e4b91a38
Revises: a1f4c8d2e705
"""
from alembic import op
import sqlalchemy as sa


revision = "c7d2e4b91a38"
down_revision = "a1f4c8d2e705"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("ml_runs", sa.Column("artifact_path", sa.String(255), nullable=True))
    op.add_column("ml_runs", sa.Column("artifact_sha256", sa.String(64), nullable=True))
    op.add_column(
        "ml_runs", sa.Column("artifact_sklearn_version", sa.String(32), nullable=True)
    )
    op.add_column(
        "ml_runs",
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    # At most one active run, enforced by the database rather than by code.
    op.create_index(
        "one_active_ml_run",
        "ml_runs",
        [sa.text("(1)")],
        unique=True,
        postgresql_where=sa.text("is_active"),
    )

    op.create_table(
        "scans",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "mobile_user_id",
            sa.Integer(),
            sa.ForeignKey("mobile_users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("url", sa.Text(), nullable=False),
        sa.Column("model_input", sa.Text(), nullable=False),
        sa.Column("category", sa.String(32), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("score_kind", sa.String(16), nullable=False, server_default="margin"),
        sa.Column(
            "model_run_id",
            sa.String(36),
            sa.ForeignKey("ml_runs.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("scans_owner_created", "scans", ["mobile_user_id", "created_at"])


def downgrade():
    op.drop_index("scans_owner_created", table_name="scans")
    op.drop_table("scans")
    op.drop_index("one_active_ml_run", table_name="ml_runs")
    op.drop_column("ml_runs", "is_active")
    op.drop_column("ml_runs", "artifact_sklearn_version")
    op.drop_column("ml_runs", "artifact_sha256")
    op.drop_column("ml_runs", "artifact_path")
