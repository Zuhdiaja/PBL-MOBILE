import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

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
            onScan: () => _selectTab(1),
            onPaste: () => _selectTab(1),
            onQr: () => _selectTab(1),
            onShare: () => _selectTab(1),
            onHistory: () => _selectTab(2),
            onProfile: () => _selectTab(4),
          ),
          const _PlaceholderPage(title: 'Scan'),
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
