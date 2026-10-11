import 'package:flutter/material.dart';

import '../data/scan_result.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onOpenDetail});

  /// Navigation is wired by the shell; this feature stays on its own data.
  final ValueChanged<int>? onOpenDetail;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Semua';

  List<String> get _filters => [
    'Semua',
    ...demoScanResults.map((item) => item.category).toSet(),
  ];

  List<ScanResultItem> get _items => _filter == 'Semua'
      ? demoScanResults
      : demoScanResults.where((item) => item.category == _filter).toList();

  @override
  Widget build(BuildContext context) => ScanPage(
    children: [
      const Text('Riwayat scan', style: pageTitleStyle),
      const SizedBox(height: 6),
      Text('${demoScanResults.length} URL pernah diperiksa', style: bodyStyle),
      const SizedBox(height: 18),
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) => _FilterChip(
            label: _filters[index],
            selected: _filters[index] == _filter,
            onTap: () => setState(() => _filter = _filters[index]),
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (_items.isEmpty)
        const InfoNote('Tidak ada hasil untuk filter ini.')
      else
        ..._buildGroupedItems(),
      const SizedBox(height: 12),
      const InfoNote('Data contoh. Riwayat scan belum tersimpan di perangkat.'),
    ],
  );

  List<Widget> _buildGroupedItems() {
    final children = <Widget>[];
    String? currentDay;

    for (final item in _items) {
      if (item.dayLabel != currentDay) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 20));
        currentDay = item.dayLabel;
        children
          ..add(
            Text(
              item.dayLabel.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          )
          ..add(const SizedBox(height: 8));
      }
      children
        ..add(
          _HistoryRow(
            item: item,
            index: demoScanResults.indexOf(item),
            onOpenDetail: widget.onOpenDetail,
          ),
        )
        ..add(const SizedBox(height: 6));
    }
    return children;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.blue : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? AppColors.blue : AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.index,
    required this.onOpenDetail,
  });

  final ScanResultItem item;
  final int index;
  final ValueChanged<int>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final color = item.categoryColor;
    final background = item.categoryBackground;

    return InkWell(
      onTap: () => onOpenDetail?.call(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                item.isSafe
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_rounded,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.url,
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
                    item.scanTime,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.confidence}% confidence',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
