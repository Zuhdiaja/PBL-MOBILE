import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  static const labels = ['Beranda', 'Statistik', 'Pindai', 'Riwayat', 'Profil'];
  static const icons = [
    Icons.home_outlined,
    Icons.bar_chart_rounded,
    Icons.crop_free_rounded,
    Icons.history_rounded,
    Icons.person_outline_rounded,
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(top: BorderSide(color: context.colors.line)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  selected: selectedIndex == i,
                  button: true,
                  label: labels[i],
                  child: ExcludeSemantics(
                    child: Material(
                      color: i != 2 && selectedIndex == i
                          ? context.colors.paleBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onDestinationSelected(i),
                        overlayColor: i == 2
                            ? const WidgetStatePropertyAll(Colors.transparent)
                            : null,
                        child: i == 2
                            ? _scanDestination(context)
                            : _destination(context, i),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _destination(BuildContext context, int index) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? context.colors.blue : context.colors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[index], size: 24, color: color),
          const SizedBox(height: 4),
          _label(index, color, isSelected),
        ],
      ),
    );
  }

  Widget _scanDestination(BuildContext context) {
    final isSelected = selectedIndex == 2;
    final color = isSelected ? context.colors.blue : context.colors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
      child: SizedBox(
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              left: 0,
              child: Center(child: _label(2, color, isSelected)),
            ),
            Positioned(
              top: -20,
              right: 0,
              left: 0,
              child: Center(
                child: Material(
                  key: const ValueKey('scan-navigation-button'),
                  color: AppColors.blue,
                  elevation: 3,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDestinationSelected(2),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        icons[2],
                        size: 25,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(int index, Color color, bool isSelected) => Text(
    labels[index],
    maxLines: 1,
    style: TextStyle(
      fontSize: 10,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: color,
    ),
  );
}
