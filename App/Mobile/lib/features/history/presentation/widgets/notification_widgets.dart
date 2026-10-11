import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.item, required this.unread});

  final AppNotification item;
  final bool unread;

  IconData get _icon => switch (item.kind) {
    NotificationKind.report => Icons.flag_rounded,
    NotificationKind.danger => Icons.warning_amber_rounded,
    NotificationKind.scan => Icons.verified_user_outlined,
  };

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
            child: Icon(_icon, color: color, size: 20),
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
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
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
