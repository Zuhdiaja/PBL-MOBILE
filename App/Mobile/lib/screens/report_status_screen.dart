import 'package:flutter/material.dart';

import '../data/demo_activity.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class ReportStatusScreen extends StatelessWidget {
  const ReportStatusScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanSubpage(
    title: 'Status laporan',
    selectedIndex: 4,
    children: [
      Text('${demoReports.length} laporan pernah dikirim', style: bodyStyle),
      const SizedBox(height: 18),
      for (final report in demoReports) ...[
        _ReportCard(report: report),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 8),
      const InfoNote('Data contoh. Laporan belum terhubung ke server.'),
    ],
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ReportItem report;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(report: report),
      ),
    ),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${report.type} · ${report.submittedTime}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: report.status),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color get _color => switch (status) {
    'Selesai' => AppColors.success,
    'Ditinjau' => AppColors.warning,
    _ => AppColors.blue,
  };

  Color get _background => switch (status) {
    'Selesai' => AppColors.paleSuccess,
    'Ditinjau' => AppColors.paleWarning,
    _ => AppColors.paleBlue,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: _color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.report});

  final ReportItem report;

  @override
  Widget build(BuildContext context) {
    final statusIndex = switch (report.status) {
      'Selesai' => 2,
      'Ditinjau' => 1,
      _ => 0,
    };
    const steps = ['Laporan dikirim', 'Sedang ditinjau', 'Selesai'];

    return ScanSubpage(
      title: 'Detail laporan',
      selectedIndex: 4,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL yang dilaporkan',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.url,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _MetaRow(label: 'Jenis laporan', value: report.type),
        const SizedBox(height: 10),
        _MetaRow(label: 'Kategori dilaporkan', value: report.reportedCategory),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Status',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _StatusBadge(status: report.status),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetaRow(label: 'Waktu dikirim', value: report.submittedTime),
        if (report.notes != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Catatan',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report.notes!,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Linimasa status',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++) ...[
          _TimelineStep(
            label: steps[i],
            done: i <= statusIndex,
            isLast: i == steps.length - 1,
          ),
        ],
        const SizedBox(height: 20),
        const InfoNote('Data contoh. Linimasa menampilkan alur simulasi.'),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.isLast,
  });

  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      children: [
        Column(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.muted,
              size: 19,
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: done ? AppColors.success : AppColors.line,
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              label,
              style: TextStyle(
                color: done ? AppColors.ink : AppColors.muted,
                fontSize: 13,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
