import 'package:flutter/foundation.dart';

import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/set_report_notifications.dart';

/// Backs the status report notification toggle on the settings screen.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.repository,
    required this.setReportNotifications,
  });

  final AccountRepository repository;
  final SetReportNotifications setReportNotifications;

  bool _reportNotificationsEnabled = true;
  bool _disposed = false;

  bool get reportNotificationsEnabled => _reportNotificationsEnabled;

  Future<void> load() async {
    final enabled = await repository.readReportNotificationsEnabled();
    if (_disposed) return;
    _reportNotificationsEnabled = enabled;
    notifyListeners();
  }

  /// Flips the preference and returns the value the repository settled on.
  Future<bool> toggleReportNotifications() async {
    final enabled = await setReportNotifications(
      !_reportNotificationsEnabled,
      repository,
    );
    if (_disposed) return enabled;
    _reportNotificationsEnabled = enabled;
    notifyListeners();
    return enabled;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
