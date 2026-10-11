import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/demo_account_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dataSource);

  final DemoAccountDataSource _dataSource;

  @override
  AccountStats readStats() => AccountStats(
    totalScans: _dataSource.readTotalScans(),
    submittedReports: _dataSource.readSubmittedReports(),
    pendingReports: _dataSource.readPendingReports(),
  );

  @override
  bool readReportNotificationsEnabled() =>
      _dataSource.readReportNotificationsEnabled();

  @override
  void writeReportNotificationsEnabled(bool enabled) =>
      _dataSource.writeReportNotificationsEnabled(enabled);
}
