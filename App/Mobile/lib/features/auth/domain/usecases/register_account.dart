import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';

typedef RegisterResult = ({UserAccount? account, AuthFailure? failure});

/// Opens a session for a newly created account.
///
/// The API enforces the same rules, but validating here keeps the form honest
/// before spending a request.
class RegisterAccount {
  const RegisterAccount();

  static const minimumPasswordLength = 12;

  Future<RegisterResult> call(
    RegisterRequest request,
    AuthRepository repository,
  ) async {
    final name = request.name.trim();
    final email = request.email.trim();
    if (name.isEmpty) {
      return (account: null, failure: const AuthFailure('Nama wajib diisi.'));
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return (
        account: null,
        failure: const AuthFailure('Gunakan alamat email yang valid.'),
      );
    }
    if (request.password.length < minimumPasswordLength) {
      return (
        account: null,
        failure: const AuthFailure(
          'Kata sandi minimal $minimumPasswordLength karakter.',
        ),
      );
    }

    try {
      final account = await repository.register(
        RegisterRequest(name: name, email: email, password: request.password),
      );
      return (account: account, failure: null);
    } on AuthFailure catch (failure) {
      return (account: null, failure: failure);
    }
  }
}
