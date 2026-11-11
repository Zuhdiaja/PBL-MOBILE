import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../domain/entities/auth_failure.dart';
import '../models/user_account_model.dart';
import 'auth_data_source.dart';
import 'token_store.dart';

/// Default API origin for local development.
///
/// Kept as a thin alias so existing callers and tests stay valid; the value
/// itself lives in [defaultApiBaseUrl] so other features can share it.
String defaultAuthApiBaseUrl() => defaultApiBaseUrl();

/// Talks to `/api/v1/mobile/auth` on the LinkGuard API.
class RemoteAuthDataSource implements AuthDataSource {
  RemoteAuthDataSource({
    required String baseUrl,
    required this.tokenStore,
    http.Client? client,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  @override
  UserAccountModel? get demoAccount => null;

  @override
  bool get isOffline => false;

  Uri _uri(String path) => Uri.parse('$baseUrl/api/v1/mobile/auth$path');

  Map<String, String> get _jsonHeaders => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, String> _authHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(_timeout);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : const {};
    } catch (_) {
      return const {};
    }
  }

  String _message(http.Response response, String fallback) {
    final error = _decode(response)['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }

  UserAccountModel _account(http.Response response) {
    final user = _decode(response)['user'];
    if (user is! Map || user['id'] == null) {
      throw const AuthFailure('Respons server tidak dikenali.');
    }
    return UserAccountModel(
      id: user['id'].toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
    );
  }

  Future<UserAccountModel> _storeSession(http.Response response) async {
    final token = _decode(response)['token'];
    if (token is! String || token.isEmpty) {
      throw const AuthFailure('Respons server tidak dikenali.');
    }
    await tokenStore.write(token);
    return _account(response);
  }

  @override
  Future<UserAccountModel?> currentAccount() async {
    final token = await tokenStore.read();
    if (token == null) return null;
    final response = await _request(
      () => _client.get(_uri('/me'), headers: _authHeaders(token)),
    );
    if (response.statusCode == 200) return _account(response);
    if (response.statusCode == 401) {
      await tokenStore.clear();
      return null;
    }
    throw AuthFailure(
      _message(response, 'Sesi tidak dapat dipulihkan. Silakan masuk kembali.'),
    );
  }

  @override
  Future<UserAccountModel?> signIn(String email, String password) async {
    final response = await _request(
      () => _client.post(
        _uri('/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (response.statusCode == 200) return _storeSession(response);
    if (response.statusCode == 401) {
      throw const AuthFailure('Email atau password salah.');
    }
    if (response.statusCode == 429) {
      throw const AuthFailure('Terlalu banyak percobaan. Coba lagi nanti.');
    }
    throw AuthFailure(_message(response, 'Tidak dapat masuk. Coba lagi.'));
  }

  @override
  Future<UserAccountModel> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _request(
      () => _client.post(
        _uri('/register'),
        headers: _jsonHeaders,
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ),
    );
    if (response.statusCode == 201) return _storeSession(response);
    if (response.statusCode == 409) {
      throw const AuthFailure('Email sudah terdaftar. Silakan masuk.');
    }
    throw AuthFailure(
      _message(response, 'Pendaftaran gagal. Periksa data Anda.'),
    );
  }

  @override
  Future<UserAccountModel> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    final hasId = idToken != null && idToken.isNotEmpty;
    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    if (!hasId && !hasAccess) {
      throw const AuthFailure('Token Google tidak valid.');
    }
    final response = await _request(
      () => _client.post(
        _uri('/google'),
        headers: _jsonHeaders,
        body: jsonEncode({
          if (hasId) 'id_token': idToken,
          if (hasAccess) 'access_token': accessToken,
        }),
      ),
    );
    if (response.statusCode == 200) return _storeSession(response);
    if (response.statusCode == 403) {
      throw AuthFailure(
        _message(response, 'Akun dinonaktifkan. Hubungi admin.'),
      );
    }
    if (response.statusCode == 409) {
      throw AuthFailure(
        _message(response, 'Email ini sudah tertaut ke akun Google lain.'),
      );
    }
    if (response.statusCode == 503) {
      throw AuthFailure(
        _message(response, 'Login Google belum dikonfigurasi.'),
      );
    }
    throw AuthFailure(_message(response, 'Login Google gagal. Coba lagi.'));
  }

  @override
  Future<void> signOut() async {
    final token = await tokenStore.read();
    if (token != null) {
      try {
        await _client
            .post(_uri('/logout'), headers: _authHeaders(token))
            .timeout(_timeout);
      } catch (_) {
        // The local session is cleared even when the server is unreachable.
      }
    }
    await tokenStore.clear();
  }
}
