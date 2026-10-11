import '../entities/auth_failure.dart';
import '../entities/user_account.dart';
import '../repositories/auth_repository.dart';

typedef RegisterResult = ({UserAccount? account, AuthFailure? failure});

/// Opens a session for a newly created account.
///
/// Registration stays as permissive as the prototype it replaces: any values
/// are accepted so the demo flow keeps working. Validation belongs to the real
/// backend once it is wired up.
class RegisterAccount {
  const RegisterAccount();

  RegisterResult call(RegisterRequest request, AuthRepository repository) {
    final account = repository.register(
      RegisterRequest(
        name: request.name.trim(),
        email: request.email.trim(),
        password: request.password,
      ),
    );
    return (account: account, failure: null);
  }
}
