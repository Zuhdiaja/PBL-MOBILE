import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/section_label.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F6FA),
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('PREFERENSI'),
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppColors.blue,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notifikasi status laporan',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6EF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        color: Color(0xFF16804A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: Color(0xFF8FA2C1)),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Pengaturan ini adalah bagian dari prototipe; pemberitahuan ditampilkan di dalam aplikasi.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: 4,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        onNavigate(index);
      },
    ),
  );
}
