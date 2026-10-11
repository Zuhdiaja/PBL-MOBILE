import '../entities/user_account.dart';
import '../repositories/account_repository.dart';

/// Reads the counts shown at the top of the profile screen.
class LoadAccountStats {
  const LoadAccountStats();

  AccountStats call(AccountRepository repository) => repository.readStats();
}
