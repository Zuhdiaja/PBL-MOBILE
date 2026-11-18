import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/failed_scan.dart';
import '../../domain/entities/scan_result.dart';

class ScanSummaryCard extends StatelessWidget {
  const ScanSummaryCard({super.key, required this.summary});
  final ScanResultSummary summary;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('${summary.totalCount} tautan diperiksa', style: sectionTitleStyle),
      const SizedBox(height: 8),
      Text(
        '${summary.safeCount} aman · ${summary.attentionCount} perlu perhatian',
        style: TextStyle(color: context.colors.muted, fontSize: 12),
      ),
    ],
  );
}

/// One URL that could not be checked.
class FailedScanCard extends StatelessWidget {
  const FailedScanCard({super.key, required this.failure});
  final FailedScan failure;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 19,
          color: context.colors.warning,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayHost(failure.url),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                failure.message,
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ScanStatPill extends StatelessWidget {
  const ScanStatPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color, background;
  @override
  Widget build(BuildContext context) =>
      Text(label, style: TextStyle(fontSize: 12, color: color));
}

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({super.key, required this.result, required this.onTap});
  final ScanResult result;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayHost(result.url),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    CategoryBadge(result.category),
                    Text(
                      result.riskLevel,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.muted,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
