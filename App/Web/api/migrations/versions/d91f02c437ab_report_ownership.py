"""Verified mobile ownership; legacy reports remain unowned.

Revision ID: d91f02c437ab
Revises: 3c08162c5839
"""
from alembic import op
import sqlalchemy as sa

revision = "d91f02c437ab"
down_revision = "3c08162c5839"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("prediction_reports", sa.Column("reporter_id", sa.Integer(), nullable=True))
    op.create_foreign_key("fk_prediction_reports_reporter_id", "prediction_reports",
                          "mobile_users", ["reporter_id"], ["id"], ondelete="SET NULL")
    op.create_index("ix_prediction_reports_reporter_id", "prediction_reports", ["reporter_id"])


def downgrade():
    op.drop_index("ix_prediction_reports_reporter_id", table_name="prediction_reports")
    op.drop_constraint("fk_prediction_reports_reporter_id", "prediction_reports", type_="foreignkey")
    op.drop_column("prediction_reports", "reporter_id")
