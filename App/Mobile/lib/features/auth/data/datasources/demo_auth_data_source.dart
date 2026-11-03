import '../../domain/entities/auth_failure.dart';
import '../models/user_account_model.dart';
import 'auth_data_source.dart';

/// In-memory stand-in for the auth backend.
///
/// It keeps one signed-in account at a time so login, register, and sign out
/// behave like a real session in previews and widget tests. The real app uses
/// [RemoteAuthDataSource].
class DemoAuthDataSource implements AuthDataSource {
  static const demoName = 'Nadia Putri';
  static const demoEmail = 'nadia@gmail.com';
  static const demoPassword = '123456';

  UserAccountModel? _session;
  UserAccountModel? _registered;

  /// Account the login form is prefilled with.
  @override
  UserAccountModel get demoAccount =>
      const UserAccountModel(id: 'demo-1', name: demoName, email: demoEmail);

  @override
  Future<UserAccountModel?> currentAccount() async => _session;

  /// Accepts the demo credentials or the account created this session.
  @override
  Future<UserAccountModel?> signIn(String email, String password) async {
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
  @override
  Future<UserAccountModel> register(
    String name,
    String email,
    String password,
  ) async {
    _registered = UserAccountModel(
      id: 'registered-1',
      name: name.isEmpty ? demoName : name,
      email: email.isEmpty ? demoEmail : email,
    );
    _registeredPassword = password;
    _session = _registered;
    return _registered!;
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
    return demoAccount;
  }

  @override
  Future<void> signOut() async => _session = null;

  String? _registeredPassword;
}
