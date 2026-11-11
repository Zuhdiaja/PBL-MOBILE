import '../config/google_config.dart';
import '../features/auth/data/datasources/account_data_source.dart';
import '../features/auth/data/datasources/auth_data_source.dart';
import '../features/auth/data/datasources/demo_account_data_source.dart';
import '../features/auth/data/datasources/plugin_google_identity_source.dart';
import '../features/auth/data/datasources/preferences_account_data_source.dart';
import '../features/auth/data/datasources/remote_auth_data_source.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/data/repositories/account_repository_impl.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/entities/user_account.dart';
import '../features/auth/domain/repositories/account_repository.dart';
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
  AuthDependencies._(
    this.tokenStore,
    this._authSource,
    this._googleIdentity,
    this.accountRepository,
  ) {
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
      repository: accountRepository,
      loadAccountStats: const LoadAccountStats(),
    );
    settings = SettingsController(
      repository: accountRepository,
      setReportNotifications: const SetReportNotifications(),
    );
  }

  factory AuthDependencies({
    AuthDataSource? authSource,
    TokenStore? tokenStore,
    GoogleIdentitySource? googleIdentity,
  }) {
    final store = tokenStore ?? SharedPreferencesTokenStore();
    final source =
        authSource ??
        RemoteAuthDataSource(
          baseUrl: defaultAuthApiBaseUrl(),
          tokenStore: store,
        );
    return AuthDependencies._(
      store,
      source,
      googleIdentity ??
          (googleSignInConfigured
              ? PluginGoogleIdentitySource()
              : const UnavailableGoogleIdentitySource()),
      AccountRepositoryImpl(_accountSourceFor(source)),
    );
  }

  /// Session storage shared with features that call the authenticated API.
  final TokenStore tokenStore;

  /// Profile figures and preferences shared with the other features.
  final AccountRepository accountRepository;

  final AuthDataSource _authSource;
  final GoogleIdentitySource _googleIdentity;

  late final AuthController auth;
  late final ProfileController profile;
  late final SettingsController settings;

  /// Keeps previews in memory while the real app persists the preferences.
  static AccountDataSource _accountSourceFor(AuthDataSource source) =>
      source.isOffline
      ? DemoAccountDataSource()
      : PreferencesAccountDataSource();

  /// Token store handed to API-backed features.
  ///
  /// Null while the app runs on an offline source, so those features keep
  /// their example data instead of calling a server that is not there.
  TokenStore? get apiTokenStore => _authSource.isOffline ? null : tokenStore;

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
