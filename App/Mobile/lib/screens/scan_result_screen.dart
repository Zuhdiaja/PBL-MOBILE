import 'package:flutter/material.dart';

import '../data/scan_result.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';
import 'scan_detail_screen.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    this.results,
    this.onNavigate,
  });

  final List<ScanResultItem>? results;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = (results != null && results!.isNotEmpty)
        ? results!
        : demoScanResults;

    final safeCount = items.where((e) => e.isSafe).length;
    final attentionCount = items.where((e) => !e.isSafe).length;

    return ScanSubpage(
      title: 'Hasil scan',
      onNavigate: onNavigate,
      selectedIndex: 2,
      children: [
        const PreviewBadge('HASIL SIMULASI'),
        const SizedBox(height: 16),
        _SummaryCard(
          totalCount: items.length,
          safeCount: safeCount,
          attentionCount: attentionCount,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: '$safeCount aman',
              color: AppColors.success,
              background: AppColors.paleSuccess,
            ),
            _StatPill(
              label: '$attentionCount perlu perhatian',
              color: AppColors.danger,
              background: AppColors.paleDanger,
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (final item in items) ...[
          _ScanResultCard(item: item, onNavigate: onNavigate),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalCount,
    required this.safeCount,
    required this.attentionCount,
  });

  final int totalCount;
  final int safeCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.paleBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'RINGKASAN PEMERIKSAAN',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.blue,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$totalCount URL selesai diperiksa',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buka setiap hasil untuk melihat indikator, confidence score, dan rekomendasi.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.item, this.onNavigate});

  final ScanResultItem item;
  final ValueChanged<int>? onNavigate;

  void _openDetail(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanDetailScreen(item: item, onNavigate: onNavigate),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.isSafe ? AppColors.success : AppColors.danger;
    final badgeBackground =
        item.isSafe ? AppColors.paleSuccess : AppColors.paleDanger;

    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.url,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.riskLevel} · ${item.confidence}% confidence',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat detail',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.blue,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
