import 'package:flutter/material.dart';

import '../../../../widgets/scan_components.dart';
import '../../domain/entities/history_entry.dart';
import '../controllers/history_controller.dart';
import '../widgets/history_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller, this.onOpenDetail});

  final HistoryController controller;

  /// Navigation is wired by the shell; this feature stays on its own data.
  final ValueChanged<HistoryEntry>? onOpenDetail;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final filters = controller.filters;

      return ScanPage(
        children: [
          const Text('Riwayat scan', style: pageTitleStyle),
          const SizedBox(height: 6),
          Text(
            '${controller.entries.length} URL pernah diperiksa',
            style: bodyStyle,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = filters[index];
                return HistoryFilterChip(
                  label: label,
                  selected: label == controller.filter,
                  onTap: () => controller.selectFilter(label),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (controller.visibleEntries.isEmpty)
            const InfoNote('Tidak ada hasil untuk filter ini.')
          else
            ..._buildGroupedItems(controller.visibleEntries),
          const SizedBox(height: 12),
          const InfoNote(
            'Data contoh. Riwayat scan belum tersimpan di perangkat.',
          ),
        ],
      );
    },
  );

  List<Widget> _buildGroupedItems(List<HistoryEntry> entries) {
    final children = <Widget>[];
    String? currentDay;

    for (final entry in entries) {
      if (entry.dayLabel != currentDay) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 20));
        currentDay = entry.dayLabel;
        children
          ..add(HistoryDayLabel(entry.dayLabel))
          ..add(const SizedBox(height: 8));
      }
      children
        ..add(HistoryRow(entry: entry, onOpenDetail: widget.onOpenDetail))
        ..add(const SizedBox(height: 6));
    }
    return children;
  }
}
