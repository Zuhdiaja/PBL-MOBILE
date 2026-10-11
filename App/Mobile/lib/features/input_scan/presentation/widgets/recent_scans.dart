import 'package:flutter/material.dart';

import '../../domain/entities/recent_scan.dart';
import '../../../../theme/app_colors.dart';

class RecentScans extends StatelessWidget {
  const RecentScans({super.key, required this.items, required this.onSelected});

  final List<RecentScan> items;
  final ValueChanged<RecentScan> onSelected;

  @override
  Widget build(BuildContext context) {
    final scans = items;
    return Column(
      children: [
        for (var i = 0; i < scans.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.line),
          _RecentScanRow(item: scans[i], onSelected: onSelected),
        ],
      ],
    );
  }
}

class _RecentScanRow extends StatelessWidget {
  const _RecentScanRow({required this.item, required this.onSelected});

  final RecentScan item;
  final ValueChanged<RecentScan> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = item.isSafe ? AppColors.success : AppColors.danger;
    final background = item.isSafe
        ? AppColors.paleSuccess
        : AppColors.paleDanger;

    return InkWell(
      onTap: () => onSelected(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.isSafe
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.url,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.scanTime,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
