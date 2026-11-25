import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../features/auth/data/datasources/token_store.dart';

/// Shared account context. Never persists bearer credentials in preference keys.
class PushAccount {
  static String? accountId;
  static final store = const SecureTokenStore();
  static Future<String> installationId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('push_installation');
    if (id == null) {
      final random = Random.secure();
      id = List.generate(
        24,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await prefs.setString('push_installation', id);
    }
    return id;
  }

  static Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    String? bearer,
  }) async {
    final token = bearer ?? await store.read();
    if (token == null) throw StateError('Sesi tidak tersedia');
    final uri = Uri.parse('${defaultApiBaseUrl()}/api/v1/mobile/$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await (method == 'POST'
                ? http.post(uri, headers: headers, body: jsonEncode(data))
                : method == 'PATCH'
                ? http.patch(uri, headers: headers, body: jsonEncode(data))
                : method == 'DELETE'
                ? http.delete(uri, headers: headers, body: jsonEncode(data))
                : http.get(uri, headers: headers))
            .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw StateError('Sinkronisasi notifikasi gagal');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<bool> preference({bool refresh = false}) async {
    final id = accountId;
    if (id == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = 'push_preference_$id';
    if (refresh) {
      final result = await request('preferences');
      await prefs.setBool(key, result['report_notifications_enabled'] == true);
    }
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setPreference(bool enabled) async {
    final id = accountId;
    if (id == null) throw StateError('Silakan masuk kembali');
    await request(
      'preferences',
      method: 'PATCH',
      data: {'report_notifications_enabled': enabled},
    );
    await (await SharedPreferences.getInstance()).setBool(
      'push_preference_$id',
      enabled,
    );
  }
}
