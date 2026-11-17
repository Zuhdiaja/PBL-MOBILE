import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermission {
  NotificationPermission(this.messaging, this.local);
  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin local;
  static const _shown = 'linkguard_notification_explanation_shown';
  Future<bool> shouldExplain() async =>
      !((await SharedPreferences.getInstance()).getBool(_shown) ?? false);
  Future<void> markExplained() async =>
      (await SharedPreferences.getInstance()).setBool(_shown, true);
  Future<bool> request() async {
    final settings = await messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> openSettings() async {
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.openAppNotificationSettings();
  }
}
