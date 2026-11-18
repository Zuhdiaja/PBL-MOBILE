import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// The server has no device registration endpoint yet. Never logs the token.
class FcmTokenManager {
  FcmTokenManager(this.messaging);
  final FirebaseMessaging messaging;
  String? token;
  StreamSubscription<String>? _subscription;
  Future<void> start() async {
    // The backend contract requires FCM registration tokens rather than FIDs.
    // ignore: deprecated_member_use
    _subscription = messaging.onTokenRefresh.listen((value) => token = value);
    // ignore: deprecated_member_use
    final initialToken = await messaging.getToken();
    token ??= initialToken;
  }

  void dispose() => _subscription?.cancel();
}
