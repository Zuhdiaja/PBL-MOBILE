"""Persistent mobile user accounts managed by dashboard admins.

Revision ID: 1a47d8ec2301
Revises: 6f42bd58580d
"""
from alembic import op
import sqlalchemy as sa

revision = "1a47d8ec2301"
down_revision = "6f42bd58580d"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("mobile_users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("email"))


def downgrade():
    op.drop_table("mobile_users")
