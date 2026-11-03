"""Mobile password and Google authentication.

Revision ID: b7c1e4a90f23
Revises: 1a47d8ec2301
"""
from alembic import op
import sqlalchemy as sa

revision = "b7c1e4a90f23"
down_revision = "1a47d8ec2301"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("mobile_users", sa.Column("google_sub", sa.String(255), nullable=True))
    op.create_unique_constraint("uq_mobile_users_google_sub", "mobile_users", ["google_sub"])
    op.add_column("mobile_users", sa.Column(
        "token_version", sa.Integer(), nullable=False, server_default="1"))
    op.alter_column("mobile_users", "password_hash", existing_type=sa.Text(), nullable=True)


def downgrade():
    op.alter_column("mobile_users", "password_hash", existing_type=sa.Text(), nullable=False)
    op.drop_column("mobile_users", "token_version")
    op.drop_constraint("uq_mobile_users_google_sub", "mobile_users", type_="unique")
    op.drop_column("mobile_users", "google_sub")
