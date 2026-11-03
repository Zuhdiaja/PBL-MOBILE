import '../repositories/auth_repository.dart';

/// Closes the current session.
class SignOut {
  const SignOut();

  Future<void> call(AuthRepository repository) => repository.signOut();
}
