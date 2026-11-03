import '../../../../presentation/load_controller.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/google_identity_source.dart';
import '../../domain/usecases/register_account.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

/// Holds the session and the state of the login and register forms.
class AuthController extends LoadController {
  AuthController({
    required this.repository,
    required this.signIn,
    required this.registerAccount,
    required this.signInWithGoogle,
    required this.googleIdentity,
    required this.signOut,
  });

  final AuthRepository repository;
  final SignIn signIn;
  final RegisterAccount registerAccount;
  final SignInWithGoogle signInWithGoogle;
  final GoogleIdentitySource googleIdentity;
  final SignOut signOut;

  UserAccount? _account;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _closed = false;

  /// Account of the current session, or null when signed out.
  UserAccount? get account => _account;

  /// Message shown after a rejected attempt, or null when there is none.
  String? get errorMessage => _errorMessage;

  /// Whether a sign in or registration request is in flight.
  bool get isSubmitting => _isSubmitting;

  bool get isSignedIn => _account != null;

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  /// Reads any session the data source already holds.
  @override
  Future<void> load() =>
      loadValue(repository.currentAccount, (value) => _account = value);

  Future<void> restore() => load();

  /// Attempts a sign in; returns true when the session opened.
  Future<bool> submitSignIn(SignInRequest request) async {
    if (_isSubmitting) return false;
    _beginSubmission();
    final result = await signIn(request, repository);
    if (_closed) return false;
    _isSubmitting = false;
    return _applyResult(result.account, result.failure);
  }

  /// Attempts a registration; returns true when the session opened.
  Future<bool> submitRegister(RegisterRequest request) async {
    if (_isSubmitting) return false;
    _beginSubmission();
    final result = await registerAccount(request, repository);
    if (_closed) return false;
    _isSubmitting = false;
    return _applyResult(result.account, result.failure);
  }

  /// Attempts a Google sign in; returns true when the session opened.
  Future<bool> submitGoogle() async {
    if (_isSubmitting) return false;
    _beginSubmission();
    final result = await signInWithGoogle(googleIdentity, repository);
    if (_closed) return false;
    _isSubmitting = false;
    return _applyResult(result.account, result.failure);
  }

  /// Closes the session and forgets the last error.
  Future<void> submitSignOut() async {
    await signOut(repository);
    if (_closed) return;
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

  void _beginSubmission() {
    _isSubmitting = true;
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
