import '../../../../widgets/load_view.dart';

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
  Widget build(BuildContext context) => LoadView(
    controller: widget.controller,
    kind: 'stats',
    subpage: false,
    builder: (context) {
      final summary = widget.controller.summary;
      if (summary.totalCount == 0) {
        return const ScanPage(
          children: [
            Text('Statistik', style: pageTitleStyle),
            SizedBox(height: 24),
            InfoNote('Belum ada pemindaian untuk ditampilkan.'),
          ],
        );
      }

      return ScanPage(
        children: [
          const Text('Statistik', style: pageTitleStyle),
          const SizedBox(height: 8),
          Text(
            'Total pemindaian',
            style: TextStyle(fontSize: 14, color: context.colors.muted),
          ),
          const SizedBox(height: 8),
          StatsTotalCard(total: summary.totalCount),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (summary.safeCount > 0)
                  Expanded(
                    flex: summary.safeCount,
                    child: Container(height: 6, color: context.colors.success),
                  ),
                if (summary.unsafeCount > 0) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    flex: summary.unsafeCount,
                    child: Container(height: 6, color: context.colors.danger),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend(
                '${summary.safeCount} aman · ${summary.safePercent}%',
                context.colors.success,
              ),
              _Legend(
                '${summary.unsafeCount} perlu perhatian · ${100 - summary.safePercent}%',
                context.colors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Aktivitas tujuh hari', style: sectionTitleStyle),
          const SizedBox(height: 12),
          const WeeklyActivityChart(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.phishing_outlined,
                  value: '${summary.phishingCount}',
                  label: 'Phishing',
                  color: context.colors.danger,
                  background: context.colors.paleDanger,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  icon: Icons.bug_report_outlined,
                  value: '${summary.malwareCount}',
                  label: 'Malware',
                  color: context.colors.danger,
                  background: context.colors.paleDanger,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  icon: Icons.flag_outlined,
                  value: '${summary.reportCount}',
                  label: 'Laporan',
                  color: context.colors.blue,
                  background: context.colors.paleBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const InfoNote(
            'Data contoh. Statistik dihitung dari riwayat simulasi.',
          ),
        ],
      );
    },
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 5, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
      ),
    ],
  );
}
