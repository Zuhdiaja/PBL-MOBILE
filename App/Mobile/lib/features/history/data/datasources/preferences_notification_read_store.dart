import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/notification_read_store.dart';

/// Keeps the read marks on the device, separate for every account.
class PreferencesNotificationReadStore implements NotificationReadStore {
  const PreferencesNotificationReadStore({required this.accountId});

  final String accountId;

  String get _key => 'linkguard_notification_reads_$accountId';

  @override
  Future<Set<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  @override
  Future<void> write(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
