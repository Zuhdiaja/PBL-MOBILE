import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';
import '../widgets/recent_scans.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onScan,
    required this.onPaste,
    required this.onQr,
    required this.onShare,
    required this.onHistory,
    required this.onProfile,
  });

  final VoidCallback onScan;
  final VoidCallback onPaste;
  final VoidCallback onQr;
  final VoidCallback onShare;
  final VoidCallback onHistory;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => ScanPage(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Beranda', style: pageTitleStyle),
                SizedBox(height: 6),
                Text('Lindungi langkah digitalmu', style: bodyStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.softSurface,
              foregroundColor: AppColors.ink,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Buka profil',
            onPressed: onProfile,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.paleBlue,
              foregroundColor: AppColors.blue,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Text(
              'NP',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      const Text(
        'Halo, Nadia',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Link mencurigakan?',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        'Cek dulu di sini.',
        style: TextStyle(
          color: AppColors.blue,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 24),
      _ScanHero(onScan: onScan),
      const SizedBox(height: 28),
      const Text('Cara cepat', style: sectionTitleStyle),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            _QuickAction(
              icon: Icons.link_rounded,
              label: 'Tempel URL',
              onTap: onPaste,
            ),
            _QuickAction(
              icon: Icons.qr_code_rounded,
              label: 'Scan QR',
              onTap: onQr,
            ),
            _QuickAction(
              icon: Icons.share_outlined,
              label: 'Bagikan link',
              onTap: onShare,
            ),
          ];
          if (MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
              children: [
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: action,
                  ),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          const Expanded(child: Text('Scan terbaru', style: sectionTitleStyle)),
          TextButton(
            onPressed: onHistory,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Lihat semua'),
          ),
        ],
      ),
      const Text(
        'Data contoh',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 8),
      const RecentScans(),
    ],
  );
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3265DB), Color(0xFF244ABA)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -76,
          right: -44,
          child: ExcludeSemantics(
            child: SizedBox(
              width: 206,
              height: 206,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final diameter in [206.0, 150.0])
                    Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Periksa sebelum klik.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketahui potensi risiko URL sebelum\nmembukanya di perangkatmu.',
                style: TextStyle(
                  color: Color(0xFFE7EFFF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onScan,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Mulai scan'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.blue,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 22, color: AppColors.blue),
              ),
              const SizedBox(height: 26),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
