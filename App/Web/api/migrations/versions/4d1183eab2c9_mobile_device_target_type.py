"""Track whether a mobile push target is a legacy token or a FID."""
from alembic import op
import sqlalchemy as sa

revision = '4d1183eab2c9'
down_revision = '7e93_push_devices'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('mobile_devices', sa.Column('target_type', sa.String(5), nullable=False, server_default='token'))
    op.create_check_constraint('mobile_device_target_type_check', 'mobile_devices', "target_type IN ('token', 'fid')")


def downgrade():
    op.drop_constraint('mobile_device_target_type_check', 'mobile_devices', type_='check')
    op.drop_column('mobile_devices', 'target_type')
