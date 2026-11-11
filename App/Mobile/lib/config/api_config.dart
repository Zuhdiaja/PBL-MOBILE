import 'package:flutter/foundation.dart';

/// Default API origin for local development.
///
/// Override it for a physical device or a deployed API:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`.
String defaultApiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (kIsWeb) return 'http://localhost:3000';
  // The Android emulator reaches the host machine through 10.0.2.2.
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
