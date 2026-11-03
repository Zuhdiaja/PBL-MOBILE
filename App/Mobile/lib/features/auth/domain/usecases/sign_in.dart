import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';

typedef SignInResult = ({UserAccount? account, AuthFailure? failure});

/// Turns the login form values into a session.
class SignIn {
  const SignIn();

  Future<SignInResult> call(
    SignInRequest request,
    AuthRepository repository,
  ) async {
    final email = request.email.trim();
    if (email.isEmpty || request.password.isEmpty) {
      return (
        account: null,
        failure: const AuthFailure('Email dan password wajib diisi.'),
      );
    }

    try {
      final account = await repository.signIn(
        SignInRequest(email: email, password: request.password),
      );
      if (account == null) {
        return (
          account: null,
          failure: const AuthFailure('Email atau password salah.'),
        );
      }
      return (account: account, failure: null);
    } on AuthFailure catch (failure) {
      return (account: null, failure: failure);
    }
  }
}
