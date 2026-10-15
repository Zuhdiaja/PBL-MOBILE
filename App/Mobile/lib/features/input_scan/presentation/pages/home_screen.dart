import '../../../../widgets/loading_states.dart';
import '../../../../widgets/load_view.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../widgets/recent_scans.dart';
import '../controllers/home_controller.dart';
import '../../domain/entities/recent_scan.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNotifications,
    required this.onRecentScan,
    required this.onScan,
    required this.onPaste,
    required this.onQr,
    required this.onShare,
    required this.onHistory,
    required this.onProfile,
    this.name = 'Nadia',
    this.initials = 'NP',
  });
  final HomeController controller;
  final VoidCallback onNotifications,
      onScan,
      onPaste,
      onQr,
      onShare,
      onHistory,
      onProfile;
  final ValueChanged<RecentScan> onRecentScan;
  final String name, initials;
  @override
  Widget build(BuildContext context) => LoadView(
    controller: controller,
    kind: 'home',
    loadingBuilder: (context) => _page(context, pending: true),
    errorBuilder: (context) => _page(context),
    builder: (context) => _page(context),
  );

  Widget _page(BuildContext context, {bool pending = false}) => ScanPage(
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinkGuardBrand(size: 21),
                const SizedBox(height: 6),
                Text(
                  'Halo, $name',
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: onNotifications,
            icon: Badge(
              smallSize: 5,
              backgroundColor: context.colors.blue,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'Buka profil',
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: context.colors.paleBlue,
                foregroundColor: context.colors.blue,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.blue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periksa tautan.',
              style: TextStyle(
                color: context.colors.onPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onScan,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Mulai pindai'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.onPrimary,
                  foregroundColor: context.colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            _QuickAction(
              icon: Icons.qr_code_rounded,
              label: 'Pindai QR',
              onTap: onQr,
            ),
            _QuickAction(
              icon: Icons.share_outlined,
              label: 'Dari aplikasi lain',
              onTap: onShare,
            ),
          ];
          if (constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
              children: [actions[0], const SizedBox(height: 10), actions[1]],
            );
          }
          return Row(
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 12),
              Expanded(child: actions[1]),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: Text('Pindai terbaru', style: sectionTitleStyle),
          ),
          TextButton(
            onPressed: onHistory,
            child: const Text('Lihat semua', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      if (pending)
        const LoadingRows(count: 2, label: 'Memuat pindai terbaru')
      else if (controller.loadError != null)
        LoadFailure(message: controller.loadError!, onRetry: controller.load)
      else ...[
        if (controller.recentScans.isEmpty)
          const InfoNote('Belum ada riwayat pindai.'),
        RecentScans(
          items: controller.recentScans.take(2).toList(),
          onSelected: onRecentScan,
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'Data contoh',
        style: TextStyle(color: context.colors.muted, fontSize: 11),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: context.colors.blue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
