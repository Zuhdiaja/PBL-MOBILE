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

  bool get reportNotificationsEnabled => _reportNotificationsEnabled;

  void load() {
    _reportNotificationsEnabled = repository.readReportNotificationsEnabled();
    notifyListeners();
  }

  /// Flips the preference and returns the value the repository settled on.
  bool toggleReportNotifications() {
    _reportNotificationsEnabled = setReportNotifications(
      !_reportNotificationsEnabled,
      repository,
    );
    notifyListeners();
    return _reportNotificationsEnabled;
  }
}
