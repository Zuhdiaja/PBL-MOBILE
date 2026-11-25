"""Native cross-platform outbox worker: python push_worker.py (no Docker/RQ fork)."""
import time
from flask import current_app
from app import create_app
from app.extensions import db
from app.models import PUSH_MAX_ATTEMPTS, PushOutbox, PredictionReport, MobileUser, MobileDevice
from app.routes.mobile_auth import session_identity, session_matches

def deliver_one():
    import firebase_admin
    from firebase_admin import messaging
    event = db.session.scalar(db.select(PushOutbox).where(
        PushOutbox.sent.is_(False), PushOutbox.attempts < PUSH_MAX_ATTEMPTS
    ).order_by(PushOutbox.id).with_for_update(skip_locked=True).limit(1))
    if event is None:
        db.session.rollback()
        return
    event.attempts += 1
    report = db.session.get(PredictionReport, event.report_id)
    user = db.session.get(MobileUser, report.reporter_id, with_for_update=True) if report and report.reporter_id else None
    if not user or not user.active or not user.report_notifications_enabled:
        event.sent = True
        db.session.commit()
        return
    try:
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app(options={'httpTimeout': 10})
        devices = db.session.scalars(db.select(MobileDevice).where(MobileDevice.user_id == user.id)).all()
        for device in devices:
            if not session_matches(user, session_identity(device.session_key)):
                db.session.delete(device)
                continue
            data = dict(report_id=str(report.id), notification_id=str(event.id), notification_type='report', body=f'Status laporan Anda: {event.status}')
            recipient = {device.target_type: device.token}
            try:
                messaging.send(messaging.Message(**recipient,
                    notification=messaging.Notification(title='LinkGuard - Pembaruan laporan', body=data['body']),
                    data=data, android=messaging.AndroidConfig(priority='high',
                        notification=messaging.AndroidNotification(channel_id='report_updates'))))
            except messaging.UnregisteredError:
                db.session.execute(db.delete(MobileDevice).where(MobileDevice.id == device.id, MobileDevice.token == device.token))
        event.sent = True
    except Exception:
        log = current_app.logger.error if event.attempts == PUSH_MAX_ATTEMPTS else current_app.logger.warning
        log('Push delivery failed for event %s (attempt %s/%s)', event.id, event.attempts, PUSH_MAX_ATTEMPTS)
    db.session.commit()


if __name__ == '__main__':
    import firebase_admin

    app = create_app()
    firebase_admin.initialize_app(options={'httpTimeout': 10}).credential.get_credential()
    while True:
        with app.app_context():
            try:
                deliver_one()
            except Exception:
                db.session.rollback()
                app.logger.warning('Push dispatcher unavailable; retrying')
        time.sleep(5)
