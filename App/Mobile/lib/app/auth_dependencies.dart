import '../config/google_config.dart';
import '../features/auth/data/datasources/auth_data_source.dart';
import '../features/auth/data/datasources/demo_account_data_source.dart';
import '../features/auth/data/datasources/plugin_google_identity_source.dart';
import '../features/auth/data/datasources/remote_auth_data_source.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/data/repositories/account_repository_impl.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/entities/user_account.dart';
import '../features/auth/domain/repositories/google_identity_source.dart';
import '../features/auth/domain/usecases/load_account_stats.dart';
import '../features/auth/domain/usecases/register_account.dart';
import '../features/auth/domain/usecases/set_report_notifications.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_in_with_google.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/controllers/profile_controller.dart';
import '../features/auth/presentation/controllers/settings_controller.dart';

/// Composition root for the auth and account feature.
///
/// By default the app talks to the LinkGuard API and keeps its bearer token on
/// the device. Tests and previews inject a [DemoAuthDataSource] instead so they
/// stay offline.
class AuthDependencies {
  AuthDependencies._(this.tokenStore, this._authSource, this._googleIdentity) {
    final authRepository = AuthRepositoryImpl(_authSource);
    auth = AuthController(
      repository: authRepository,
      signIn: const SignIn(),
      registerAccount: const RegisterAccount(),
      signInWithGoogle: const SignInWithGoogle(),
      googleIdentity: _googleIdentity,
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

  factory AuthDependencies({
    AuthDataSource? authSource,
    TokenStore? tokenStore,
    GoogleIdentitySource? googleIdentity,
  }) {
    final store = tokenStore ?? SharedPreferencesTokenStore();
    return AuthDependencies._(
      store,
      authSource ??
          RemoteAuthDataSource(
            baseUrl: defaultAuthApiBaseUrl(),
            tokenStore: store,
          ),
      googleIdentity ??
          (googleSignInConfigured
              ? PluginGoogleIdentitySource()
              : const UnavailableGoogleIdentitySource()),
    );
  }

  /// Session storage shared with features that call the authenticated API.
  final TokenStore tokenStore;

  final AuthDataSource _authSource;
  final GoogleIdentitySource _googleIdentity;
  final _accountSource = DemoAccountDataSource();

  late final AuthController auth;
  late final ProfileController profile;
  late final SettingsController settings;

  /// Credentials the login form prefills when the source is a demo. Null once
  /// the real API is in use.
  UserAccount? get demoAccount => _authSource.demoAccount?.toEntity();

  /// Neutral stand-in for previews when no session is open.
  UserAccount get placeholderAccount =>
      const UserAccount(id: '', name: 'Pengguna', email: '');

  /// Account the shell renders; previews fall back to the demo identity.
  UserAccount get displayAccount => demoAccount ?? placeholderAccount;

  void dispose() {
    auth.dispose();
    profile.dispose();
    settings.dispose();
  }
}
