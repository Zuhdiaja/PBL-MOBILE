import 'package:flutter/material.dart';

import '../../../../notifications/push_notification_service.dart';

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

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool? _granted;
  bool _saving = false;
  Future<void> _refreshPermission() async {
    final permission = PushNotificationService.active?.permission;
    if (permission == null) return;
    final granted = await permission.isGranted();
    if (mounted) setState(() => _granted = granted);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _enable() async {
    final permission = PushNotificationService.active?.permission;
    if (permission == null) return;
    if (!await permission.request()) await permission.openSettings();
    await _refreshPermission();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.load().catchError((Object _) {});
    _refreshPermission();
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
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 19),
                label: Text('Sistem'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 19),
                label: Text('Terang'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 19),
                label: Text('Gelap'),
              ),
            ],
            selected: {
              AppThemeScope.maybeOf(context)?.mode ?? ThemeMode.system,
            },
            onSelectionChanged: (values) {
              AppThemeScope.maybeOf(context)?.select(values.first);
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
          onChanged: _saving
              ? null
              : (_) async {
                  setState(() => _saving = true);
                  try {
                    await widget.controller.toggleReportNotifications();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preferensi gagal disimpan. Coba lagi.',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
        ),
        if (PushNotificationService.active != null) ...[
          Text(
            _granted == null
                ? 'Memeriksa izin notifikasi…'
                : _granted!
                ? 'Izin notifikasi aktif'
                : 'Izin notifikasi belum aktif',
          ),
          if (_granted == false)
            TextButton(
              onPressed: _enable,
              child: const Text('Aktifkan notifikasi'),
            ),
        ],
        const SizedBox(height: 12),
        Divider(color: context.colors.line),
        const SizedBox(height: 18),
        const InfoNote('Pemberitahuan ditampilkan di dalam aplikasi.'),
      ],
    ),
  );
}
