import 'package:flutter/material.dart';

import '../data/scan_result.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';
import 'report_prediction_screen.dart';

class ScanDetailScreen extends StatelessWidget {
  const ScanDetailScreen({
    super.key,
    this.item,
    this.onNavigate,
  });

  final ScanResultItem? item;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final scanItem = item ?? demoScanResults.first;
    final statusColor = scanItem.isSafe ? AppColors.success : AppColors.danger;
    final statusBackground =
        scanItem.isSafe ? AppColors.paleSuccess : AppColors.paleDanger;
    final indicators = scanItem.indicators ?? scanItem.defaultIndicators;

    return ScanSubpage(
      title: 'Detail hasil',
      onNavigate: onNavigate,
      selectedIndex: 2,
      children: [
        const PreviewBadge('HASIL SIMULASI'),
        const SizedBox(height: 16),

        // Hero Classification Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  Text(
                    scanItem.category,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'HASIL KLASIFIKASI',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scanItem.category,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scanItem.url,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Metrics Row (Risk level & Confidence score)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Tingkat risiko',
                child: Text(
                  scanItem.riskLevel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Confidence score',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${scanItem.confidence}%',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: scanItem.confidence / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.line,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Rekomendasi Keamanan Section
        const Text(
          'Rekomendasi keamanan',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.blue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scanItem.recommendation ?? scanItem.defaultRecommendation,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Indikator yang Terdeteksi Section
        const Text(
          'Indikator yang terdeteksi',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final indicator in indicators)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  scanItem.isSafe ? Icons.check_rounded : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    indicator,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        const Divider(color: AppColors.line),
        const SizedBox(height: 16),

        // Metadata Details
        _MetaRow(label: 'Waktu scan', value: scanItem.scanTime),
        const SizedBox(height: 10),
        _MetaRow(label: 'Model klasifikasi', value: scanItem.modelName),
        const SizedBox(height: 10),
        _MetaRow(label: 'Metode', value: scanItem.method),

        const SizedBox(height: 24),

        // Report Prediction Result Action
        ScanButton(
          label: 'Lapor hasil prediksi',
          icon: Icons.flag_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportPredictionScreen(
                item: scanItem,
                onNavigate: onNavigate,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
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
