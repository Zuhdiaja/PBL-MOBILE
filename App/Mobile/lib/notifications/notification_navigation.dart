import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/history/data/models/report_status_model.dart';
import '../features/history/domain/entities/report_status.dart';

/// Keeps the latest notification destination until the signed-in shell is ready.
class NotificationNavigation extends ChangeNotifier {
  Map<String, dynamic>? _pending;
  void accept(Map<String, dynamic> data) {
    _pending = data;
    notifyListeners();
  }

  Map<String, dynamic>? take() {
    final value = _pending;
    _pending = null;
    return value;
  }
}

/// Fetches only the signed-in user's report through the existing mobile API.
Future<ReportStatus?> fetchNotificationReport(
  String id,
  TokenStore? store,
) async {
  if (int.tryParse(id) == null || int.parse(id) <= 0) return null;
  if (store == null) return null;
  final token = await store.read();
  if (token == null) return null;
  try {
    final response = await http
        .get(
          Uri.parse('${defaultApiBaseUrl()}/api/v1/mobile/reports/$id'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    final report = data is Map ? data['report'] : null;
    return report is Map<String, dynamic>
        ? ReportStatusModel.fromJson(report).toEntity()
        : null;
  } catch (_) {
    return null;
  }
}
