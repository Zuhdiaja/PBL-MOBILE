import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/user_account.dart';

/// Header card showing the account avatar, name, and email.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.paleBlue,
          child: Text(
            account.initials,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                account.email,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// One number with its caption, shown in the profile stats row.
class AccountStatTile extends StatelessWidget {
  const AccountStatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    ),
  );
}

/// A tappable row in one of the profile action groups.
class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final Widget? trailing;

  static const dangerColor = Color(0xFFC83D42);

  @override
  Widget build(BuildContext context) {
    final color = danger ? dangerColor : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? dangerColor : AppColors.blue, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9AA7BA),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Count badge shown next to the report status row.
class ProfileCountBadge extends StatelessWidget {
  const ProfileCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    width: 17,
    height: 17,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFB63C42),
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
