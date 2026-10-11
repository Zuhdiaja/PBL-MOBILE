import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/section_label.dart';
import '../../domain/entities/user_account.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// Shows the signed-in account, its activity, and the account actions.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    required this.account,
    required this.onSettings,
    required this.onSignOut,
    required this.onReportStatus,
    required this.onNotifications,
  });

  final ProfileController controller;

  /// Account of the current session.
  final UserAccount account;

  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onReportStatus;
  final VoidCallback onNotifications;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SingleChildScrollView(
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
            ProfileHeader(account: widget.account),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: AccountStatTile(
                    value: '${controller.stats.totalScans}',
                    label: 'Total scan',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AccountStatTile(
                    value: '${controller.stats.submittedReports}',
                    label: 'Laporan dikirim',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel('AKTIVITAS'),
            ProfileActionTile(
              icon: Icons.description_outlined,
              title: 'Status laporan',
              trailing: ProfileCountBadge(
                count: controller.stats.pendingReports,
              ),
              onTap: widget.onReportStatus,
            ),
            ProfileActionTile(
              icon: Icons.notifications_none,
              title: 'Notifikasi',
              onTap: widget.onNotifications,
            ),
            const SizedBox(height: 15),
            const SectionLabel('AKUN'),
            ProfileActionTile(
              icon: Icons.settings_outlined,
              title: 'Pengaturan',
              onTap: widget.onSettings,
            ),
            ProfileActionTile(
              icon: Icons.logout,
              title: 'Keluar akun',
              danger: true,
              onTap: widget.onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
