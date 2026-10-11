import '../features/auth/data/datasources/demo_account_data_source.dart';
import '../features/auth/data/datasources/demo_auth_data_source.dart';
import '../features/auth/data/repositories/account_repository_impl.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/entities/user_account.dart';
import '../features/auth/domain/usecases/load_account_stats.dart';
import '../features/auth/domain/usecases/register_account.dart';
import '../features/auth/domain/usecases/set_report_notifications.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/controllers/profile_controller.dart';
import '../features/auth/presentation/controllers/settings_controller.dart';

/// Composition root for the auth and account feature.
///
/// Concrete demo data stays here so auth widgets never import it. One instance
/// is created by the app and shared by login, profile, and settings, so the
/// session survives navigation between them.
class AuthDependencies {
  AuthDependencies() {
    final authRepository = AuthRepositoryImpl(_authSource);
    auth = AuthController(
      repository: authRepository,
      signIn: const SignIn(),
      registerAccount: const RegisterAccount(),
      signOut: const SignOut(),
    );
    profile = ProfileController(
      repository: AccountRepositoryImpl(_accountSource),
      loadAccountStats: const LoadAccountStats(),
    );
    settings = SettingsController(
      repository: AccountRepositoryImpl(_accountSource),
      setReportNotifications: const SetReportNotifications(),
    );
  }

  final _authSource = DemoAuthDataSource();
  final _accountSource = DemoAccountDataSource();

  late final AuthController auth;
  late final ProfileController profile;
  late final SettingsController settings;

  /// Credentials the login form is prefilled with.
  UserAccount get demoAccount => _authSource.demoAccount.toEntity();

  void dispose() {
    auth.dispose();
    profile.dispose();
    settings.dispose();
  }
}
