import 'package:flutter/foundation.dart';

import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/load_account_stats.dart';

/// Supplies the profile header and the counts above the action list.
class ProfileController extends ChangeNotifier {
  ProfileController({required this.repository, required this.loadAccountStats});

  final AccountRepository repository;
  final LoadAccountStats loadAccountStats;

  AccountStats _stats = const AccountStats.empty();

  AccountStats get stats => _stats;

  void load() {
    _stats = loadAccountStats(repository);
    notifyListeners();
  }
}
