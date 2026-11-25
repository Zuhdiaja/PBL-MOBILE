import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_navigation.dart';

class LocalNotificationService {
  LocalNotificationService(this.navigation);
  final NotificationNavigation navigation;
  final plugin = FlutterLocalNotificationsPlugin();
  static const channel = AndroidNotificationChannel(
    'report_updates',
    'Laporan LinkGuard',
    description: 'Pembaruan laporan LinkGuard',
    importance: Importance.high,
  );
  void _tap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) navigation.accept(data);
    } catch (_) {
      /* Ignore malformed payloads. */
    }
  }

  Future<void> initialize() async {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('linkguard_mark'),
      ),
      onDidReceiveNotificationResponse: (response) => _tap(response.payload),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _tap(launch?.notificationResponse?.payload);
    }
  }

  Future<void> show(Map<String, dynamic> data, String body) => plugin.show(
    id:
        (data['notification_id']?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString())
            .hashCode &
        0x7fffffff,
    title: 'LinkGuard - Laporan Baru',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'report_updates',
        'Laporan LinkGuard',
        channelDescription: 'Pembaruan laporan LinkGuard',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(data),
  );
}
