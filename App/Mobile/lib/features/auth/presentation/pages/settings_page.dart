import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/scan_components.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });
  final SettingsController controller;
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => ScanSubpage(
      title: 'Pengaturan',
      children: [
        Text(
          'Tampilan',
          style: TextStyle(color: context.colors.muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Text(
          'Pilih tema yang nyaman untuk Anda.',
          style: TextStyle(color: context.colors.muted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.light_mode_outlined, size: 19),
                label: Text('Terang'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.dark_mode_outlined, size: 19),
                label: Text('Gelap'),
              ),
            ],
            selected: {context.colors.dark},
            onSelectionChanged: (values) {
              AppThemeScope.maybeOf(context)?.value = values.first
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? context.colors.paleBlue
                    : context.colors.surface,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? context.colors.blue
                    : context.colors.muted,
              ),
              visualDensity: VisualDensity.standard,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Preferensi',
          style: TextStyle(color: context.colors.muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.notifications_none_rounded,
            color: context.colors.muted,
          ),
          title: const Text(
            'Notifikasi status laporan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Dapatkan kabar saat laporan ditinjau.',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.muted,
              height: 1.6,
            ),
          ),
          value: widget.controller.reportNotificationsEnabled,
          onChanged: (_) => widget.controller.toggleReportNotifications(),
        ),
        const SizedBox(height: 12),
        Divider(color: context.colors.line),
        const SizedBox(height: 18),
        const InfoNote('Pemberitahuan ditampilkan di dalam aplikasi.'),
      ],
    ),
  );
}
