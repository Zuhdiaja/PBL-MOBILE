import 'package:flutter/material.dart';

import '../../../../data/demo_activity.dart';
import '../../domain/entities/app_notification.dart';

/// Maps the legacy notification model onto the notification entity.
class AppNotificationModel {
  const AppNotificationModel({required this.id, required this.item});

  final String id;
  final NotificationItem item;

  AppNotification toEntity() => AppNotification(
    id: id,
    title: item.title,
    body: item.body,
    time: item.time,
    group: item.group,
    kind: _kindOf(item.icon),
    unread: item.unread,
  );

  static NotificationKind _kindOf(IconData icon) {
    if (icon == Icons.warning_amber_rounded) return NotificationKind.danger;
    if (icon == Icons.verified_user_outlined) return NotificationKind.scan;
    return NotificationKind.report;
  }
}
