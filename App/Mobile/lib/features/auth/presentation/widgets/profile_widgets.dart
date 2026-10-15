import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/user_account.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.account});
  final UserAccount account;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 32,
        backgroundColor: context.colors.paleBlue,
        foregroundColor: context.colors.blue,
        child: Text(
          account.initials,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              account.email,
              style: TextStyle(color: context.colors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}

class AccountStatTile extends StatelessWidget {
  const AccountStatTile({super.key, required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: value,
          style: TextStyle(
            color: context.colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: ' $label'),
      ],
    ),
    style: TextStyle(fontSize: 13, color: context.colors.muted),
  );
}

class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 16,
        leading: Icon(
          icon,
          size: 23,
          color: danger ? context.colors.danger : context.colors.muted,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: danger ? context.colors.danger : context.colors.ink,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
            Icon(
              Icons.chevron_right_rounded,
              size: 21,
              color: danger ? context.colors.danger : context.colors.muted,
            ),
          ],
        ),
        onTap: onTap,
      ),
      Divider(height: 1, color: context.colors.line),
    ],
  );
}

class ProfileCountBadge extends StatelessWidget {
  const ProfileCountBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: context.colors.paleBlue,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count',
      style: TextStyle(color: context.colors.blue, fontSize: 12),
    ),
  );
}
