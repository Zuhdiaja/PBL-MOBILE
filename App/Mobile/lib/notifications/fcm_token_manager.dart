import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_account.dart';

/// Serializes authenticated device registration. Never logs tokens.
class FcmTokenManager {
  FcmTokenManager(this.messaging);
  final FirebaseMessaging messaging;
  String? token;
  StreamSubscription<String>? _subscription;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  Future<void> sync() {
    final account = PushAccount.accountId;
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (_disposed ||
          account == null ||
          account != PushAccount.accountId ||
          token == null) {
        return;
      }
      final bearer = await PushAccount.store.read();
      if (bearer == null || account != PushAccount.accountId) return;
      await PushAccount.request(
        'devices',
        method: 'POST',
        bearer: bearer,
        data: {
          'installation_id': await PushAccount.installationId(),
          'token': token,
          'platform': 'android',
        },
      );
    });
    return _pending;
  }

  Future<void> unlink() async {
    PushAccount.accountId = null;
    try {
      await _pending.catchError((Object _) {});
      await PushAccount.request(
        'devices',
        method: 'DELETE',
        data: {'installation_id': await PushAccount.installationId()},
      );
    } catch (_) {
      /* Backend logout also revokes the device registration. */
    }
  }

  Future<void> start() async {
    // The backend contract requires FCM registration tokens rather than FIDs.
    // ignore: deprecated_member_use
    _subscription = messaging.onTokenRefresh.listen((value) {
      token = value;
      unawaited(sync().catchError((Object _) {}));
    });
    // ignore: deprecated_member_use
    final initialToken = await messaging.getToken();
    token ??= initialToken;
    await sync();
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
  }
}
