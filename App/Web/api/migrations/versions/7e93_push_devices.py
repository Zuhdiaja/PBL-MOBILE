"""Device registrations, push preferences, and transactional outbox."""
from alembic import op
import sqlalchemy as sa

revision = '7e93_push_devices'
down_revision = '182f54ca98dd'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('mobile_users', sa.Column('report_notifications_enabled', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.create_table('mobile_devices',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('installation_id', sa.String(128), nullable=False, unique=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('mobile_users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('token', sa.String(4096), nullable=False, unique=True),
        sa.Column('session_key', sa.String(128), nullable=False),
        sa.Column('platform', sa.String(16), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False))
    op.create_index('ix_mobile_devices_user_id', 'mobile_devices', ['user_id'])
    op.create_table('push_outbox',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('report_id', sa.Integer(), sa.ForeignKey('prediction_reports.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(32), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False),
        sa.Column('sent', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False))


def downgrade():
    op.drop_table('push_outbox')
    op.drop_table('mobile_devices')
    op.drop_column('mobile_users', 'report_notifications_enabled')
