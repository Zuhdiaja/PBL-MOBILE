import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import 'fcm_token_manager.dart';
import 'local_notification_service.dart';
import 'notification_navigation.dart';
import 'notification_permission.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification payloads are displayed by Android. Do not display twice.
}

class PushNotificationService {
  final navigation = NotificationNavigation();
  late final local = LocalNotificationService(navigation);
  late final permission = NotificationPermission(
    FirebaseMessaging.instance,
    local.plugin,
  );
  late final tokens = FcmTokenManager(FirebaseMessaging.instance);
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandler);
    await local.initialize();
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        final body = message.notification?.body ?? message.data['body'];
        if (body is String && body.isNotEmpty) local.show(message.data, body);
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => navigation.accept(message.data),
      ),
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) navigation.accept(initial.data);
    try {
      await tokens.start();
    } catch (_) {
      /* Retry on a later launch. */
    }
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    tokens.dispose();
    navigation.dispose();
  }
}
