import '../../../../widgets/load_view.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller});

  final NotificationsController controller;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _markAllRead() {
    widget.controller.markAllRead();
    showScanMessage(context, 'Semua notifikasi ditandai telah dibaca.');
  }

  @override
  Widget build(BuildContext context) => LoadView(
    controller: widget.controller,
    kind: 'notifications',
    subpage: true,
    builder: (context) {
      final controller = widget.controller;
      final unreadCount = controller.unreadCount;

      return ScanSubpage(
        title: 'Notifikasi',
        children: [
          Text(
            'Pemberitahuan saat laporan selesai ditinjau.',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.muted,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  unreadCount > 0
                      ? '$unreadCount notifikasi belum dibaca'
                      : 'Semua notifikasi telah dibaca',
                  style: TextStyle(fontSize: 11, color: context.colors.muted),
                ),
              ),
              TextButton(
                onPressed: unreadCount > 0 ? _markAllRead : null,
                child: const Text(
                  'Tandai semua dibaca',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          if (controller.notifications.isEmpty)
            const InfoNote('Belum ada notifikasi.'),
          ...controller.notifications.map(
            (item) =>
                NotificationRow(item: item, unread: controller.isUnread(item)),
          ),
          const SizedBox(height: 22),
          const InfoNote('Data contoh. Notifikasi belum terhubung ke server.'),
        ],
      );
    },
  );
}
