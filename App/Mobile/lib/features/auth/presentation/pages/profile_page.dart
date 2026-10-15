import '../../../../widgets/loading_states.dart';
import '../../../../widgets/load_view.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
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
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return LoadView(
      controller: controller,
      kind: 'profile',
      loadingBuilder: (context) => _page(context, pending: true),
      errorBuilder: (context) => _page(context),
      builder: (context) => _page(context),
    );
  }

  Widget _page(BuildContext context, {bool pending = false}) {
    final controller = widget.controller;
    return ScanPage(
      children: [
        const Text('Profil', style: pageTitleStyle),
        const SizedBox(height: 24),
        ProfileHeader(account: widget.account),
        const SizedBox(height: 24),
        ProfileActionTile(
          icon: Icons.settings_outlined,
          title: 'Pengaturan',
          onTap: widget.onSettings,
        ),
        ProfileActionTile(
          icon: Icons.description_outlined,
          title: 'Status laporan',
          trailing: pending
              ? const SkeletonBox(width: 24, height: 20)
              : ProfileCountBadge(count: controller.stats.pendingReports),
          onTap: widget.onReportStatus,
        ),
        ProfileActionTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifikasi',
          onTap: widget.onNotifications,
        ),
        const SizedBox(height: 22),
        if (pending)
          LoadingPulse(
            child: Semantics(
              label: 'Memuat jumlah aktivitas',
              liveRegion: true,
              child: const Row(
                children: [
                  SkeletonBox(width: 84, height: 22),
                  SizedBox(width: 28),
                  SkeletonBox(width: 84, height: 22),
                ],
              ),
            ),
          )
        else if (controller.loadError != null)
          LoadFailure(message: controller.loadError!, onRetry: controller.load)
        else
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              AccountStatTile(
                value: '${controller.stats.totalScans}',
                label: 'pemindaian',
              ),
              AccountStatTile(
                value: '${controller.stats.submittedReports}',
                label: 'laporan',
              ),
            ],
          ),
        const SizedBox(height: 32),
        ProfileActionTile(
          icon: Icons.logout_rounded,
          title: 'Keluar akun',
          danger: true,
          onTap: widget.onSignOut,
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'LinkGuard',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
