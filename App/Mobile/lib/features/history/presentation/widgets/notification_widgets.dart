import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.item, required this.unread});
  final AppNotification item;
  final bool unread;
  @override
  Widget build(BuildContext context) {
    final color = item.kind == NotificationKind.danger
        ? context.colors.danger
        : context.colors.success;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              item.kind == NotificationKind.danger
                  ? Icons.warning_amber_rounded
                  : Icons.verified_user_outlined,
              color: color,
              size: 20,
            ),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread)
                      Icon(Icons.circle, color: context.colors.blue, size: 5),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.body,
                  style: TextStyle(
                    color: context.colors.muted,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.time,
                  style: TextStyle(color: context.colors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
