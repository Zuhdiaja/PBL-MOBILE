import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bearer token issued by the LinkGuard API.
abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// Stores the token on the device so the session survives restarts.
class SharedPreferencesTokenStore implements TokenStore {
  static const _key = 'linkguard_mobile_token';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String token) async =>
      (await SharedPreferences.getInstance()).setString(_key, token);

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

/// Keeps the token for the lifetime of the object; used by tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
