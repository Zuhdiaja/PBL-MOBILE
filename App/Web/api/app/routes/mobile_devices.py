"""Authenticated device registration and account push preferences."""
from flask import g, jsonify
from app.extensions import db
from app.models import MobileDevice
from .mobile_auth import mobile, mobile_required, body, error, bearer_token, _token_key


@mobile.post('/devices')
@mobile_required
def register_device():
    data = body()
    installation, token = data.get('installation_id'), data.get('token')
    if (not isinstance(installation, str) or not 1 <= len(installation) <= 128
            or not isinstance(token, str) or not 1 <= len(token) <= 4096
            or data.get('platform') != 'android'):
        return error('invalid_device', 'Data perangkat tidak valid.')
    # Serialize upserts so simultaneous launch/refresh requests cannot violate
    # the unique installation or token constraints (PostgreSQL transaction lock).
    db.session.execute(db.text('SELECT pg_advisory_xact_lock(73193001)'))
    device = db.session.scalar(db.select(MobileDevice).filter_by(installation_id=installation))
    duplicate = db.session.scalar(db.select(MobileDevice).filter_by(token=token))
    if duplicate is not None and duplicate is not device:
        db.session.delete(duplicate)
        db.session.flush()
    if device is None:
        device = MobileDevice(installation_id=installation)
        db.session.add(device)
    device.user_id, device.token = g.mobile_user.id, token
    device.session_key = _token_key(bearer_token())
    db.session.commit()
    return jsonify(registered=True)


@mobile.delete('/devices')
@mobile_required
def unregister_device():
    installation = body().get('installation_id')
    if not isinstance(installation, str):
        return error('invalid_device', 'ID instalasi tidak valid.')
    db.session.execute(db.delete(MobileDevice).where(
        MobileDevice.installation_id == installation,
        MobileDevice.user_id == g.mobile_user.id,
        MobileDevice.session_key == _token_key(bearer_token())))
    db.session.commit()
    return jsonify(registered=False)


@mobile.get('/preferences')
@mobile_required
def get_preferences():
    return jsonify(report_notifications_enabled=g.mobile_user.report_notifications_enabled)


@mobile.patch('/preferences')
@mobile_required
def update_preferences():
    enabled = body().get('report_notifications_enabled')
    if type(enabled) is not bool:
        return error('invalid_preference', 'Preferensi harus boolean.')
    g.mobile_user.report_notifications_enabled = enabled
    db.session.commit()
    return jsonify(report_notifications_enabled=enabled)
