import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    height: 66,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
      NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_rounded),
        label: 'Statistik',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ],
  );
}
