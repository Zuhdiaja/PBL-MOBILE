import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RecentScans extends StatelessWidget {
  const RecentScans({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _ExampleScan(
        domain: 'bank-login.example.test',
        date: '18 Sep 2026, 09:42',
        category: 'Phishing',
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        background: AppColors.paleDanger,
      ),
      Divider(height: 1, color: AppColors.line),
      _ExampleScan(
        domain: 'docs.example.test',
        date: '18 Sep 2026, 08:15',
        category: 'Aman',
        icon: Icons.verified_user_outlined,
        color: AppColors.success,
        background: AppColors.paleSuccess,
      ),
    ],
  );
}

class _ExampleScan extends StatelessWidget {
  const _ExampleScan({
    required this.domain,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String domain;
  final String date;
  final String category;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Padding(
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
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                domain,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                date,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
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
  );
}
