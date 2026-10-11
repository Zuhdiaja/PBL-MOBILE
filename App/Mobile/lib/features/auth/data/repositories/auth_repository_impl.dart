import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/demo_auth_data_source.dart';
import '../models/user_account_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final DemoAuthDataSource _dataSource;

  @override
  UserAccount? currentAccount() => _dataSource.readSession()?.toEntity();

  @override
  UserAccount? signIn(SignInRequest request) =>
      _dataSource.signIn(request.email, request.password)?.toEntity();

  @override
  UserAccount register(RegisterRequest request) => _dataSource
      .register(request.name, request.email, request.password)
      .toEntity();

  @override
  void signOut() => _dataSource.clearSession();

  /// Model used by the login form to prefill the demo credentials.
  UserAccountModel get demoAccount => _dataSource.demoAccount;
}
