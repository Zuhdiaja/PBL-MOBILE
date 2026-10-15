import 'dart:async';

import '../entities/user_account.dart';

/// Credentials submitted to the login form.
class SignInRequest {
  const SignInRequest({required this.email, required this.password});

  final String email;
  final String password;
}

/// Details submitted to the registration form.
class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

/// Owns the session: signing in, registering, and signing out.
abstract class AuthRepository {
  /// Account of the current session, or null when signed out.
  FutureOr<UserAccount?> currentAccount();

  /// Validates credentials and opens a session on success.
  UserAccount? signIn(SignInRequest request);

  /// Creates an account and opens a session for it.
  UserAccount register(RegisterRequest request);

  /// Clears the current session.
  void signOut();
}
