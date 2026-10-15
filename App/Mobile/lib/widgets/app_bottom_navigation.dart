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
  static const labels = ['Beranda', 'Pindai', 'Riwayat', 'Statistik', 'Profil'];
  static const icons = [
    Icons.home_outlined,
    Icons.crop_free_rounded,
    Icons.history_rounded,
    Icons.bar_chart_rounded,
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
                      color: selectedIndex == i
                          ? context.colors.paleBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onDestinationSelected(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 1,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[i],
                                size: 24,
                                color: selectedIndex == i
                                    ? context.colors.blue
                                    : context.colors.muted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                labels[i],
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selectedIndex == i
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selectedIndex == i
                                      ? context.colors.blue
                                      : context.colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
