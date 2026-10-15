import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const AppThemeScope({
    super.key,
    required ValueNotifier<ThemeMode> controller,
    required super.child,
  }) : super(notifier: controller);
  static ValueNotifier<ThemeMode>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}

ThemeData linkGuardTheme(Brightness brightness) {
  final c = AppPalette(brightness == Brightness.dark);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c.fieldBorder),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: c.paper,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: brightness,
        ).copyWith(
          primary: c.blue,
          onPrimary: c.onPrimary,
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.muted,
          outline: c.fieldBorder,
          outlineVariant: c.line,
          error: c.danger,
          onError: c.onPrimary,
          errorContainer: c.paleDanger,
        ),
    dividerColor: c.line,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.18,
        letterSpacing: -1,
        color: c.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -.8,
        color: c.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -.5,
        color: c.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: c.ink, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: c.ink, height: 1.6),
      bodySmall: TextStyle(fontSize: 12, color: c.muted, height: 1.6),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: TextStyle(color: c.muted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: c.blue, width: 1.5),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: c.danger)),
      errorStyle: TextStyle(color: c.danger, fontSize: 12),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.blue,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        backgroundColor: c.surface,
        minimumSize: const Size(48, 50),
        side: BorderSide(color: c.fieldBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: c.blue,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: c.ink,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.paper, fontFamily: 'Manrope'),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.blue : c.line,
      ),
    ),
  );
}
