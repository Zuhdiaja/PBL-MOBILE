import 'package:flutter/material.dart';

import '../data/demo_activity.dart';
import '../data/scan_result.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = demoScanResults.length;
    final safeCount = demoScanResults.where((e) => e.isSafe).length;
    final unsafeCount = total - safeCount;
    final phishingCount = demoScanResults
        .where((e) => e.category == 'Phishing')
        .length;
    final malwareCount = demoScanResults
        .where((e) => e.category == 'Malware')
        .length;
    final reportCount = demoReports.length;
    final safePercent = total == 0 ? 0 : (safeCount * 100 / total).round();

    return ScanPage(
      children: [
        const Text('Statistik', style: pageTitleStyle),
        const SizedBox(height: 6),
        const Text('Ringkasan aktivitas pemeriksaan', style: bodyStyle),
        const SizedBox(height: 22),
        _TotalCard(total: total),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.18,
          children: [
            _StatCard(
              icon: Icons.verified_user_outlined,
              value: '$safeCount',
              label: 'URL aman',
              color: AppColors.success,
              background: AppColors.paleSuccess,
            ),
            _StatCard(
              icon: Icons.warning_amber_rounded,
              value: '$unsafeCount',
              label: 'URL berbahaya',
              color: AppColors.danger,
              background: AppColors.paleDanger,
            ),
            _StatCard(
              icon: Icons.phishing_outlined,
              value: '$phishingCount',
              label: 'Phishing ditemukan',
              color: AppColors.blue,
              background: AppColors.paleBlue,
            ),
            _StatCard(
              icon: Icons.bug_report_outlined,
              value: '$malwareCount',
              label: 'Malware ditemukan',
              color: AppColors.danger,
              background: AppColors.paleDanger,
            ),
            _StatCard(
              icon: Icons.flag_outlined,
              value: '$reportCount',
              label: 'Jumlah laporan',
              color: AppColors.blue,
              background: AppColors.paleBlue,
            ),
            _StatCard(
              icon: Icons.percent_rounded,
              value: '$safePercent%',
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
        const _WeeklyChart(),
        const SizedBox(height: 12),
        const InfoNote('Data contoh. Statistik dihitung dari riwayat simulasi.'),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3265DB), Color(0xFF244ABA)],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total scan',
                style: TextStyle(
                  color: Color(0xFFE7EFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  static const _values = [1, 2, 2, 3, 3, 4, 5];
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Bar(value: _values[i], day: _days[i])),
        ],
      ],
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.day});

  final int value;
  final String day;

  @override
  Widget build(BuildContext context) {
    final isLast = day == _WeeklyChart._days.last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 18.0 + value * 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isLast ? AppColors.blue : AppColors.paleBlue,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}
