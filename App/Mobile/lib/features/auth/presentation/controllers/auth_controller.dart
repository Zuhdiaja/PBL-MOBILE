import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_account.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';

/// Holds the session and the state of the login and register forms.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.repository,
    required this.signIn,
    required this.registerAccount,
    required this.signOut,
  });

  final AuthRepository repository;
  final SignIn signIn;
  final RegisterAccount registerAccount;
  final SignOut signOut;

  UserAccount? _account;
  String? _errorMessage;

  /// Account of the current session, or null when signed out.
  UserAccount? get account => _account;

  /// Message shown after a rejected attempt, or null when there is none.
  String? get errorMessage => _errorMessage;

  bool get isSignedIn => _account != null;

  /// Reads any session the data source already holds.
  void restore() {
    _account = repository.currentAccount();
    notifyListeners();
  }

  /// Attempts a sign in; returns true when the session opened.
  bool submitSignIn(SignInRequest request) {
    final result = signIn(request, repository);
    return _applyResult(result.account, result.failure);
  }

  /// Attempts a registration; returns true when the session opened.
  bool submitRegister(RegisterRequest request) {
    final result = registerAccount(request, repository);
    return _applyResult(result.account, result.failure);
  }

  /// Closes the session and forgets the last error.
  void submitSignOut() {
    signOut(repository);
    _account = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the error after the page has shown it.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  bool _applyResult(UserAccount? account, AuthFailure? failure) {
    _account = account;
    _errorMessage = failure?.message;
    notifyListeners();
    return account != null;
  }
}
