import '../models/user_account_model.dart';

/// In-memory stand-in for the auth backend.
///
/// It keeps one signed-in account at a time so login, register, and sign out
/// behave like a real session while the app is still a prototype.
class DemoAuthDataSource {
  static const demoName = 'Nadia Putri';
  static const demoEmail = 'nadia@gmail.com';
  static const demoPassword = '123456';

  UserAccountModel? _session;
  UserAccountModel? _registered;

  /// Account the login form is prefilled with.
  UserAccountModel get demoAccount =>
      const UserAccountModel(id: 'demo-1', name: demoName, email: demoEmail);

  UserAccountModel? readSession() => _session;

  /// Accepts the demo credentials or the account created this session.
  UserAccountModel? signIn(String email, String password) {
    final normalized = email.trim().toLowerCase();

    final isDemo = normalized == demoEmail && password == demoPassword;
    final isRegistered =
        _registered != null &&
        _registered!.email.toLowerCase() == normalized &&
        _registeredPassword == password;

    if (!isDemo && !isRegistered) return null;

    final account = isDemo ? demoAccount : _registered!;
    _session = account;
    return account;
  }

  /// Registration always succeeds so the prototype flow keeps working.
  UserAccountModel register(String name, String email, String password) {
    _registered = UserAccountModel(
      id: 'registered-1',
      name: name.isEmpty ? demoName : name,
      email: email.isEmpty ? demoEmail : email,
    );
    _registeredPassword = password;
    _session = _registered;
    return _registered!;
  }

  void clearSession() => _session = null;

  String? _registeredPassword;
}
