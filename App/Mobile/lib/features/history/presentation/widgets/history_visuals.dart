import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/history_entry.dart';

/// Maps history entries onto the shared theme tokens.
class HistoryVisuals {
  const HistoryVisuals._();

  static Color categoryColor(HistoryEntry entry) {
    if (entry.isSafe) return AppColors.success;
    return switch (entry.category) {
      'Spam' || 'Defacement' => AppColors.warning,
      _ => AppColors.danger,
    };
  }

  static Color categoryBackground(HistoryEntry entry) {
    if (entry.isSafe) return AppColors.paleSuccess;
    return switch (entry.category) {
      'Spam' || 'Defacement' => AppColors.paleWarning,
      _ => AppColors.paleDanger,
    };
  }

  static IconData categoryIcon(HistoryEntry entry) =>
      entry.isSafe ? Icons.verified_user_outlined : Icons.warning_amber_rounded;
}
