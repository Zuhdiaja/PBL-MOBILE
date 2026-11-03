import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';
import '../repositories/google_identity_source.dart';

typedef GoogleSignInResult = ({UserAccount? account, AuthFailure? failure});

/// Exchanges a platform Google identity for a LinkGuard session.
class SignInWithGoogle {
  const SignInWithGoogle();

  Future<GoogleSignInResult> call(
    GoogleIdentitySource google,
    AuthRepository repository,
  ) async {
    String? idToken;
    try {
      idToken = await google.obtainIdToken();
    } catch (_) {
      return (
        account: null,
        failure: const AuthFailure(
          'Login Google tidak dapat dimulai. Coba lagi.',
        ),
      );
    }
    if (idToken == null || idToken.isEmpty) {
      return (
        account: null,
        failure: const AuthFailure('Login Google dibatalkan.'),
      );
    }

    try {
      final account = await repository.signInWithGoogle(idToken);
      return (account: account, failure: null);
    } on AuthFailure catch (failure) {
      return (account: null, failure: failure);
    }
  }
}
