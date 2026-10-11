import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../controllers/stats_controller.dart';
import '../widgets/stats_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.controller});

  final StatsController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final summary = widget.controller.summary;

      return ScanPage(
        children: [
          const Text('Statistik', style: pageTitleStyle),
          const SizedBox(height: 6),
          const Text('Ringkasan aktivitas pemeriksaan', style: bodyStyle),
          const SizedBox(height: 22),
          StatsTotalCard(total: summary.totalCount),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.18,
            children: [
              StatsCard(
                icon: Icons.verified_user_outlined,
                value: '${summary.safeCount}',
                label: 'URL aman',
                color: AppColors.success,
                background: AppColors.paleSuccess,
              ),
              StatsCard(
                icon: Icons.warning_amber_rounded,
                value: '${summary.unsafeCount}',
                label: 'URL berbahaya',
                color: AppColors.danger,
                background: AppColors.paleDanger,
              ),
              StatsCard(
                icon: Icons.phishing_outlined,
                value: '${summary.phishingCount}',
                label: 'Phishing ditemukan',
                color: AppColors.blue,
                background: AppColors.paleBlue,
              ),
              StatsCard(
                icon: Icons.bug_report_outlined,
                value: '${summary.malwareCount}',
                label: 'Malware ditemukan',
                color: AppColors.danger,
                background: AppColors.paleDanger,
              ),
              StatsCard(
                icon: Icons.flag_outlined,
                value: '${summary.reportCount}',
                label: 'Jumlah laporan',
                color: AppColors.blue,
                background: AppColors.paleBlue,
              ),
              StatsCard(
                icon: Icons.percent_rounded,
                value: '${summary.safePercent}%',
                label: 'Proporsi URL aman',
                color: AppColors.success,
                background: AppColors.paleSuccess,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aktivitas 7 hari',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const WeeklyActivityChart(),
          const SizedBox(height: 12),
          const InfoNote(
            'Data contoh. Statistik dihitung dari riwayat simulasi.',
          ),
        ],
      );
    },
  );
}
