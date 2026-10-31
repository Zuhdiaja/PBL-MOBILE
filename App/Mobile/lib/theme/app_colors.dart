import 'package:flutter/material.dart';

/// The reference palette, retained for non-contextual visualization helpers.
class AppColors {
  AppColors._();
  static const ink = Color(0xFF182C4B);
  static const blue = Color(0xFF2454D3);
  static const muted = Color(0xFF5D6A7F);
  static const line = Color(0xFFE0E6EF);
  static const paleBlue = Color(0xFFE9F0FF);
  static const softSurface = Color(0xFFEDF2F8);
  static const danger = Color(0xFFB33245);
  static const paleDanger = Color(0xFFFBECEF);
  static const warning = Color(0xFF8B5B17);
  static const paleWarning = Color(0xFFFFF3DD);
  static const success = Color(0xFF267553);
  static const paleSuccess = Color(0xFFE7F3EC);

  /// Warna kopian di atas latar scanner, sama pada mode terang dan gelap.
  static const scannerCopy = Color(0xFFC6D7EF);

  /// Aksen utama di atas latar scanner, sama pada mode terang dan gelap.
  static const scannerAccent = Color(0xFF9BBCFF);
}

class AppPalette {
  const AppPalette(this.dark);
  final bool dark;
  Color get paper => dark ? const Color(0xFF101D2D) : const Color(0xFFF7F9FC);
  Color get surface => dark ? const Color(0xFF182638) : Colors.white;
  Color get ink => dark ? const Color(0xFFE9EFF9) : AppColors.ink;
  Color get muted => dark ? const Color(0xFFA9B8CE) : AppColors.muted;
  Color get line => dark ? const Color(0xFF304157) : AppColors.line;
  Color get blue => dark ? const Color(0xFF9BBCFF) : AppColors.blue;
  Color get paleBlue => dark ? const Color(0xFF233B60) : AppColors.paleBlue;
  Color get softSurface =>
      dark ? const Color(0xFF203249) : AppColors.softSurface;
  Color get fieldBorder =>
      dark ? const Color(0xFF627996) : const Color(0xFF7C8BA3);
  Color get onPrimary => dark ? const Color(0xFF10203A) : Colors.white;
  Color get danger => dark ? const Color(0xFFFFA5B4) : AppColors.danger;
  Color get paleDanger => dark ? const Color(0xFF3C2634) : AppColors.paleDanger;
  Color get success => dark ? const Color(0xFF86DAB5) : AppColors.success;
  Color get paleSuccess =>
      dark ? const Color(0xFF193A32) : AppColors.paleSuccess;
  Color get warning => dark ? const Color(0xFFF4CD87) : AppColors.warning;
  Color get paleWarning =>
      dark ? const Color(0xFF3D3222) : AppColors.paleWarning;
  Color get skeleton =>
      dark ? const Color(0xFF2A3C52) : const Color(0xFFE0E7F0);
  Color get scanner => dark ? const Color(0xFF1A3962) : const Color(0xFF173D70);

  /// Permukaan kartu ilustrasi dan kartu ringkasan di atas latar scanner.
  Color get artworkSurface => dark ? const Color(0xFF182638) : Colors.white;

  /// Garis tepi kartu ilustrasi dan kartu ringkasan.
  Color get artworkLine =>
      dark ? const Color(0xFF304157) : const Color(0xFFE3EAF4);

  /// Latar plat ikon di dalam kartu ilustrasi.
  Color get artworkTint =>
      dark ? const Color(0xFF233B60) : const Color(0xFFF1F5FC);
  Color status(String category) => (category == 'Aman' || category == 'Benign')
      ? success
      : (category == 'Spam' || category == 'Defacement')
      ? warning
      : danger;
  Color statusBackground(String category) =>
      (category == 'Aman' || category == 'Benign')
      ? paleSuccess
      : (category == 'Spam' || category == 'Defacement')
      ? paleWarning
      : paleDanger;
}

extension LinkGuardPalette on BuildContext {
  AppPalette get colors =>
      AppPalette(Theme.of(this).brightness == Brightness.dark);
}
