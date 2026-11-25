import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_account.dart';

/// Synchronizes the Firebase installation with the signed-in account.
class FcmRegistration {
  FcmRegistration(this.messaging);
  final FirebaseMessaging messaging;
  String? _fid;
  StreamSubscription<String>? _subscription;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  Future<void> sync() {
    final account = PushAccount.accountId;
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (_disposed ||
          account == null ||
          account != PushAccount.accountId ||
          _fid == null) {
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
          'fid': _fid,
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
    _subscription = messaging.onRegistered.listen((fid) {
      _fid = fid;
      unawaited(sync().catchError((Object _) {}));
    });
    try {
      await messaging.register();
    } on FirebaseException catch (error) {
      debugPrint('Registrasi FCM gagal (${error.code})');
    }
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
  }
}
