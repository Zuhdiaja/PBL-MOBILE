import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bearer token issued by the LinkGuard API.
abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// Stores the token on the device so the session survives restarts.
class SecureTokenStore implements TokenStore {
  const SecureTokenStore({this.storage = const FlutterSecureStorage()});

  final FlutterSecureStorage storage;
  static const _key = 'linkguard_mobile_token';
  static Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  @override
  Future<String?> read() => _serialize(() async {
    final token = await storage.read(key: _key);
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy == null) return token;
    if (token == null) await storage.write(key: _key, value: legacy);
    await prefs.remove(_key);
    return token ?? legacy;
  });

  @override
  Future<void> write(String token) => _serialize(() async {
    await storage.write(key: _key, value: token);
    await (await SharedPreferences.getInstance()).remove(_key);
  });

  @override
  Future<void> clear() => _serialize(() async {
    await (await SharedPreferences.getInstance()).remove(_key);
    await storage.delete(key: _key);
  });
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
