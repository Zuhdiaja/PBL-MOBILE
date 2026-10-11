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
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  void _markAllRead() {
    widget.controller.markAllRead();
    showScanMessage(context, 'Semua notifikasi ditandai telah dibaca.');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final unreadCount = controller.unreadCount;

      return ScanSubpage(
        title: 'Notifikasi',
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unreadCount > 0
                      ? '$unreadCount notifikasi belum dibaca'
                      : 'Semua notifikasi telah dibaca',
                  style: bodyStyle,
                ),
              ),
              TextButton(
                onPressed: unreadCount > 0 ? _markAllRead : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Tandai semua dibaca'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildGroupedItems(controller),
          const SizedBox(height: 8),
          const InfoNote('Data contoh. Notifikasi belum terhubung ke server.'),
        ],
      );
    },
  );

  List<Widget> _buildGroupedItems(NotificationsController controller) {
    final children = <Widget>[];
    String? currentGroup;

    for (final item in controller.notifications) {
      if (item.group != currentGroup) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 18));
        currentGroup = item.group;
        children
          ..add(
            Text(
              currentGroup.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          )
          ..add(const SizedBox(height: 6));
      }
      children.add(
        NotificationRow(item: item, unread: controller.isUnread(item)),
      );
    }
    return children;
  }
}
