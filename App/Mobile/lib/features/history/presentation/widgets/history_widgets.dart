import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/history_entry.dart';

class HistoryDayLabel extends StatelessWidget {
  const HistoryDayLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      label,
      style: TextStyle(color: context.colors.muted, fontSize: 11),
    ),
  );
}

class HistoryFilterChip extends StatelessWidget {
  const HistoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: selected ? 2 : 1,
            color: selected ? context.colors.blue : context.colors.line,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? context.colors.blue : context.colors.muted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.entry,
    required this.onOpenDetail,
  });
  final HistoryEntry entry;
  final ValueChanged<HistoryEntry>? onOpenDetail;
  @override
  Widget build(BuildContext context) => Semantics(
    label: entry.url,
    child: InkWell(
      onTap: () => onOpenDetail?.call(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                categoryIcon(entry.category),
                size: 20,
                color: context.colors.status(entry.category),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayHost(entry.url),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        displayTime(entry.scanTime),
                        style: TextStyle(
                          color: context.colors.muted,
                          fontSize: 10,
                        ),
                      ),
                      CategoryBadge(entry.category),
                      Text(
                        'Keyakinan ${entry.confidence}%',
                        style: TextStyle(
                          color: context.colors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
