import pytest
from firebase_admin import messaging

from app.extensions import db
from app.models import MobileDevice, MobileUser
from push_worker import deliver_one
from test_mobile_reports import _token


def test_device_rotation_logout_and_isolation(app, client):
    headers = _token(client)
    data = dict(installation_id='test-install', token='old-token', platform='android')
    assert client.post('/api/v1/mobile/devices', json=data).status_code == 401
    assert client.post('/api/v1/mobile/devices', json=data, headers=headers).status_code == 200
    data['token'] = 'rotated-token'
    assert client.post('/api/v1/mobile/devices', json=data, headers=headers).status_code == 200
    other = _token(client, email='other-device@example.com')
    assert client.delete('/api/v1/mobile/devices', json=data, headers=other).status_code == 200
    with app.app_context():
        rows = db.session.scalars(db.select(MobileDevice)).all()
        assert len(rows) == 1
        assert rows[0].token == 'rotated-token'
    assert client.post('/api/v1/mobile/auth/logout', headers=headers).status_code == 200
    with app.app_context():
        assert db.session.scalar(db.select(db.func.count(MobileDevice.id))) == 0


def test_preferences_validate_and_persist(app, client):
    headers = _token(client)
    path = '/api/v1/mobile/preferences'
    assert client.get(path, headers=headers).json['report_notifications_enabled'] is True
    assert client.patch(path, json={'report_notifications_enabled': 'false'}, headers=headers).status_code == 400
    assert client.patch(path, json={'report_notifications_enabled': False}, headers=headers).status_code == 200
    assert client.get(path, headers=headers).json['report_notifications_enabled'] is False


def test_device_transfers_between_accounts(app, client):
    first = _token(client)
    second = _token(client, email='second-device@example.com')
    data = dict(installation_id='shared-phone', token='same-token', platform='android')
    client.post('/api/v1/mobile/devices', json=data, headers=first)
    client.post('/api/v1/mobile/devices', json=data, headers=second)
    client.post('/api/v1/mobile/auth/logout', headers=first)
    with app.app_context():
        device = db.session.scalar(db.select(MobileDevice))
        assert db.session.get(MobileUser, device.user_id).email == 'second-device@example.com'


@pytest.mark.parametrize(('target_type', 'target'), [('fid', 'c123456789012345678901'), ('token', 'legacy-token')])
def test_report_push_uses_registered_target(app, authenticated, monkeypatch, target_type, target):
    client, admin_headers = authenticated
    mobile_headers = _token(client)
    device = dict(installation_id='push-test-installation', platform='android')
    path = '/api/v1/mobile/devices'
    assert client.post(path, headers=mobile_headers, json={**device, 'fid': 'invalid'}).status_code == 400
    assert client.post(path, headers=mobile_headers, json={
        **device, 'fid': 'c123456789012345678901', 'token': 'legacy-token',
    }).status_code == 400
    assert client.post(path, headers=mobile_headers, json={**device, target_type: target}).status_code == 200
    report = client.post('/api/v1/mobile/reports', headers=mobile_headers, json={
        'url': 'https://example.test', 'type': 'False Positive', 'category': 'Benign',
    }).json['report']
    assert client.patch(f"/api/v1/reports/{report['id']}", headers=admin_headers, json={'status': 'review'}).status_code == 200

    monkeypatch.setattr('firebase_admin.get_app', lambda: object())
    sent = []
    monkeypatch.setattr(messaging, 'send', sent.append)
    with app.app_context():
        deliver_one()
    message, = sent
    assert message.fid == (target if target_type == 'fid' else None)
    assert message.token == (target if target_type == 'token' else None)
    assert message.data['report_id'] == str(report['id'])
    assert message.android.notification.channel_id == 'report_updates'
