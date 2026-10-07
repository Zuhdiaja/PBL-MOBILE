import 'package:flutter/material.dart';

import '../data/demo_account.dart';
import '../theme/app_colors.dart';
import '../widgets/section_label.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'report_status_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Akun dan preferensi Anda',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.paleBlue,
                child: Text(
                  'NP',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DemoAccount.name,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    DemoAccount.email,
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        const Row(
          children: [
            Expanded(
              child: _StatTile(value: '8', label: 'Total scan'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _StatTile(value: '3', label: 'Laporan dikirim'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionLabel('AKTIVITAS'),
        _ProfileAction(
          icon: Icons.description_outlined,
          title: 'Status laporan',
          trailing: const _CountBadge(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReportStatusScreen(),
            ),
          ),
        ),
        _ProfileAction(
          icon: Icons.notifications_none,
          title: 'Notifikasi',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const SectionLabel('AKUN'),
        _ProfileAction(
          icon: Icons.settings_outlined,
          title: 'Pengaturan',
          onTap: onSettings,
        ),
        _ProfileAction(
          icon: Icons.logout,
          title: 'Keluar akun',
          danger: true,
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

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

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
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

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFC83D42) : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? const Color(0xFFC83D42) : AppColors.blue,
              size: 17,
            ),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 17,
    height: 17,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFB63C42),
      shape: BoxShape.circle,
    ),
    child: const Text(
      '1',
      style: TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
