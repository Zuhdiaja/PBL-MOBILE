import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../models/user_account_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  @override
  Future<UserAccount?> currentAccount() async =>
      (await _dataSource.currentAccount())?.toEntity();

  @override
  Future<UserAccount?> signIn(SignInRequest request) async =>
      (await _dataSource.signIn(request.email, request.password))?.toEntity();

  @override
  Future<UserAccount> register(RegisterRequest request) async =>
      (await _dataSource.register(
        request.name,
        request.email,
        request.password,
      )).toEntity();

  @override
  Future<UserAccount> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async => (await _dataSource.signInWithGoogle(
    idToken: idToken,
    accessToken: accessToken,
  )).toEntity();

  @override
  Future<void> signOut() => _dataSource.signOut();

  /// Model used by the login form to prefill preview credentials.
  UserAccountModel? get demoAccount => _dataSource.demoAccount;
}
