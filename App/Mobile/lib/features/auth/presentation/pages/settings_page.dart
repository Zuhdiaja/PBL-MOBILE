import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_navigation.dart';
import '../../../../widgets/section_label.dart';
import '../controllers/settings_controller.dart';

/// Shows the account preferences.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final SettingsController controller;

  /// Used by the bottom bar so it can return to another tab.
  final ValueChanged<int> onNavigate;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
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
                    _PreferenceBadge(
                      enabled: controller.reportNotificationsEnabled,
                      onTap: controller.toggleReportNotifications,
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
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Color(0xFF8FA2C1),
                    ),
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
          widget.onNavigate(index);
        },
      ),
    );
  }
}

/// Shows the preference state and lets the user flip it.
class _PreferenceBadge extends StatelessWidget {
  const _PreferenceBadge({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFE8F6EF) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        enabled ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: enabled ? const Color(0xFF16804A) : AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
