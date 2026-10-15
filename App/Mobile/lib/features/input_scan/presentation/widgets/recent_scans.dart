import 'package:flutter/material.dart';

import '../../domain/entities/recent_scan.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';

class RecentScans extends StatelessWidget {
  const RecentScans({super.key, required this.items, required this.onSelected});
  final List<RecentScan> items;
  final ValueChanged<RecentScan> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        InkWell(
          onTap: () => onSelected(item),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    categoryIcon(item.category),
                    size: 21,
                    color: context.colors.status(item.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayHost(item.url),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Text(
                            displayTime(item.scanTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.muted,
                            ),
                          ),
                          CategoryBadge(item.category),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
