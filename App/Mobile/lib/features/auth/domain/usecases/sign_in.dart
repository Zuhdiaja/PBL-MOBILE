import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';

typedef SignInResult = ({UserAccount? account, AuthFailure? failure});

/// Turns the login form values into a session.
class SignIn {
  const SignIn();

  SignInResult call(SignInRequest request, AuthRepository repository) {
    final email = request.email.trim();
    if (email.isEmpty || request.password.isEmpty) {
      return (
        account: null,
        failure: const AuthFailure('Email dan password wajib diisi.'),
      );
    }

    final account = repository.signIn(
      SignInRequest(email: email, password: request.password),
    );
    if (account == null) {
      return (
        account: null,
        failure: const AuthFailure('Email atau password salah.'),
      );
    }
    return (account: account, failure: null);
  }
}
