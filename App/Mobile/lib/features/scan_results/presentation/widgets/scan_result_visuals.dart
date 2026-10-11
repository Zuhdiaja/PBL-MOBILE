import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/scan_result.dart';

/// Maps a result onto the shared theme tokens.
///
/// The results and detail pages have always colored every unsafe result the
/// same way, regardless of category, so this keeps that behavior.
class ScanResultVisuals {
  const ScanResultVisuals._();

  static Color statusColor(ScanResult result) =>
      result.isSafe ? AppColors.success : AppColors.danger;

  static Color statusBackground(ScanResult result) =>
      result.isSafe ? AppColors.paleSuccess : AppColors.paleDanger;
}
