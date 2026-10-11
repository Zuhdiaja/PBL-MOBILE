/// Topic of a notification; the actual icon is chosen in presentation.
enum NotificationKind { report, danger, scan }

/// One entry of the notification list.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.group,
    required this.kind,
    required this.unread,
  });

  final String id;
  final String title;
  final String body;
  final String time;

  /// 'Hari ini' atau 'Sebelumnya'.
  final String group;
  final NotificationKind kind;
  final bool unread;
}
