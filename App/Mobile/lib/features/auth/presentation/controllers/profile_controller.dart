import '../../../../presentation/load_controller.dart';

import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/load_account_stats.dart';

/// Supplies the profile header and the counts above the action list.
class ProfileController extends LoadController {
  ProfileController({required this.repository, required this.loadAccountStats});

  final AccountRepository repository;
  final LoadAccountStats loadAccountStats;

  AccountStats _stats = const AccountStats.empty();

  AccountStats get stats => _stats;

  @override
  Future<void> load() {
    return loadValue(
      () => loadAccountStats(repository),
      (value) => _stats = value,
    );
  }
}
