import 'dart:async';

/// Text handed to LinkGuard through the operating system share sheet.
abstract class ShareIntentSource {
  /// Text shared while the app was closed. Consumed once.
  Future<String?> takeInitialText();

  /// Text shared while the app is already running.
  Stream<String> textStream();

  void dispose();
}
