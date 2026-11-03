import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';
import '../repositories/google_identity_source.dart';

typedef GoogleSignInResult = ({UserAccount? account, AuthFailure? failure});

/// Exchanges platform Google tokens for a LinkGuard session.
class SignInWithGoogle {
  const SignInWithGoogle();

  Future<GoogleSignInResult> call(
    GoogleIdentitySource google,
    AuthRepository repository,
  ) async {
    GoogleTokens tokens;
    try {
      tokens = await google.obtainTokens();
    } on AuthFailure catch (failure) {
      return (account: null, failure: failure);
    } catch (_) {
      return (
        account: null,
        failure: const AuthFailure(
          'Login Google tidak dapat dimulai. Coba lagi.',
        ),
      );
    }
    if (tokens.isEmpty) {
      return (
        account: null,
        failure: const AuthFailure('Login Google dibatalkan.'),
      );
    }

    try {
      final account = await repository.signInWithGoogle(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      return (account: account, failure: null);
    } on AuthFailure catch (failure) {
      return (account: null, failure: failure);
    }
  }
}
