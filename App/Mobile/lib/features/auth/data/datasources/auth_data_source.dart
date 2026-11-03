import '../models/user_account_model.dart';

/// Session operations the repository needs.
///
/// Two implementations exist: [DemoAuthDataSource] keeps everything in memory
/// for previews and widget tests, while RemoteAuthDataSource talks to the
/// LinkGuard API.
abstract class AuthDataSource {
  /// Account of the stored session, or null when there is none.
  Future<UserAccountModel?> currentAccount();

  /// Returns the account on success, or null when the credentials are wrong.
  Future<UserAccountModel?> signIn(String email, String password);

  /// Creates an account and opens a session for it.
  Future<UserAccountModel> register(String name, String email, String password);

  /// Opens a session from a Google ID token.
  Future<UserAccountModel> signInWithGoogle(String idToken);

  /// Closes the session.
  Future<void> signOut();

  /// Credentials the login form may prefill. Only demo sources provide it.
  UserAccountModel? get demoAccount => null;
}
