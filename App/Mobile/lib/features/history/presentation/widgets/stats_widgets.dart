import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class StatsTotalCard extends StatelessWidget {
  const StatsTotalCard({super.key, required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          '$total',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -1.5,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: context.colors.softSurface,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          '7 hari terakhir',
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
      ),
    ],
  );
}

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String value, label;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.muted),
        ),
      ],
    ),
  );
}

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key, required this.days});
  final Map<DateTime, int> days;
  static const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty)
      return const Text('Belum ada aktivitas untuk ditampilkan.');
    final entries = days.entries.toList(growable: false);
    final peak = days.values.reduce(
      (left, right) => left > right ? left : right,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < entries.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entries[i].value}',
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: peak == 0 ? 3 : 3 + 73 * entries[i].value / peak,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: i == entries.length - 1
                            ? context.colors.blue
                            : context.colors.paleBlue,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dayNames[entries[i].key.weekday - 1],
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
