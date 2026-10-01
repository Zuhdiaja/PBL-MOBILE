import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scan_qr_screen.dart';
import 'scan_url_screen.dart';
import 'settings_screen.dart';
import 'share_link_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _scanKey = GlobalKey<ScanUrlScreenState>();

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

  void _openScan({bool paste = false}) {
    _selectTab(1);
    if (paste) _scanKey.currentState?.pasteIntoFirstField();
  }

  void _openQr() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanQrScreen(onNavigate: _selectTab),
    ),
  );

  void _openShare() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShareLinkScreen(onNavigate: _selectTab),
    ),
  );

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(onNavigate: _selectTab),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            onScan: _openScan,
            onPaste: () => _openScan(paste: true),
            onQr: _openQr,
            onShare: _openShare,
            onHistory: () => _selectTab(2),
            onProfile: () => _selectTab(4),
          ),
          ScanUrlScreen(key: _scanKey, onQr: _openQr, onShare: _openShare),
          const _PlaceholderPage(title: 'Riwayat'),
          const _PlaceholderPage(title: 'Statistik'),
          ProfileScreen(onSettings: _openSettings),
        ],
      ),
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectTab,
    ),
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
