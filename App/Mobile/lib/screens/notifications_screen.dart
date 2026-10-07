import 'package:flutter/material.dart';

import '../data/demo_activity.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _readTitles = <String>{};

  bool _isUnread(NotificationItem item) =>
      item.unread && !_readTitles.contains(item.title);

  void _markAllRead() {
    setState(() {
      for (final item in demoNotifications) {
        if (item.unread) _readTitles.add(item.title);
      }
    });
    showScanMessage(context, 'Semua notifikasi ditandai telah dibaca.');
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = demoNotifications.where(_isUnread).length;

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
        ..._buildGroupedItems(),
        const SizedBox(height: 8),
        const InfoNote('Data contoh. Notifikasi belum terhubung ke server.'),
      ],
    );
  }

  List<Widget> _buildGroupedItems() {
    final children = <Widget>[];
    String? currentGroup;

    for (final item in demoNotifications) {
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
      children.add(_NotificationRow(item: item, unread: _isUnread(item)));
    }
    return children;
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.unread});

  final NotificationItem item;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final color = unread ? AppColors.blue : AppColors.muted;
    final background = unread ? AppColors.paleBlue : AppColors.softSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: unread ? AppColors.ink : AppColors.muted,
                          fontSize: 13,
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
