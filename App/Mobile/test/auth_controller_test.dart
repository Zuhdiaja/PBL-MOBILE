import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/domain/entities/auth_failure.dart';
import 'package:pbl_semester5/features/auth/domain/entities/user_account.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/account_repository.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/google_identity_source.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/load_account_stats.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/register_account.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/set_report_notifications.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_in.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_out.dart';
import 'package:pbl_semester5/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pbl_semester5/features/auth/presentation/controllers/profile_controller.dart';
import 'package:pbl_semester5/features/auth/presentation/controllers/settings_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.accepts = true});

  final bool accepts;

  UserAccount? _session;
  var signOutCalls = 0;

  @override
  Future<UserAccount?> currentAccount() async => _session;

  @override
  Future<UserAccount> register(RegisterRequest request) async {
    _session = UserAccount(
      id: 'registered-1',
      name: request.name.isEmpty ? 'Nadia Putri' : request.name,
      email: request.email.isEmpty ? 'nadia@gmail.com' : request.email,
    );
    return _session!;
  }

  @override
  Future<UserAccount> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    if (!accepts) throw const AuthFailure('Token Google tidak valid.');
    return _session = const UserAccount(
      id: 'google-1',
      name: 'Nadia Google',
      email: 'nadia@gmail.com',
    );
  }

  @override
  Future<UserAccount?> signIn(SignInRequest request) async {
    if (!accepts) return null;
    return _session = const UserAccount(
      id: 'demo-1',
      name: 'Nadia Putri',
      email: 'nadia@gmail.com',
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _session = null;
  }
}

class _FailingAuthRepository extends _FakeAuthRepository {
  @override
  Future<UserAccount?> signIn(SignInRequest request) async =>
      throw const AuthFailure('Tidak dapat terhubung ke server.');
}

class _FakeGoogleIdentity implements GoogleIdentitySource {
  _FakeGoogleIdentity([this.token = 'google-token']);

  final String? token;

  @override
  Future<GoogleTokens> obtainTokens() async => GoogleTokens(idToken: token);
}

class _FakeAccountRepository implements AccountRepository {
  bool notificationsEnabled = true;

  @override
  AccountStats readStats() =>
      const AccountStats(totalScans: 8, submittedReports: 3, pendingReports: 1);

  @override
  bool readReportNotificationsEnabled() => notificationsEnabled;

  @override
  void writeReportNotificationsEnabled(bool enabled) =>
      notificationsEnabled = enabled;
}

void main() {
  group('AuthController', () {
    AuthController build(
      _FakeAuthRepository repository, {
      GoogleIdentitySource? google,
    }) => AuthController(
      repository: repository,
      signIn: const SignIn(),
      registerAccount: const RegisterAccount(),
      signInWithGoogle: const SignInWithGoogle(),
      googleIdentity: google ?? _FakeGoogleIdentity(),
      signOut: const SignOut(),
    );

    test('starts signed out with no error', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      expect(controller.isSignedIn, isFalse);
      expect(controller.account, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('a successful sign in exposes the account', () async {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      final signedIn = await controller.submitSignIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(signedIn, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.account?.name, 'Nadia Putri');
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('a rejected sign in keeps the error message', () async {
      final controller = build(_FakeAuthRepository(accepts: false));
      addTearDown(controller.dispose);

      final signedIn = await controller.submitSignIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
      );

      expect(signedIn, isFalse);
      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, 'Email atau password salah.');
    });

    test('a transport failure is shown instead of thrown', () async {
      final controller = build(_FailingAuthRepository());
      addTearDown(controller.dispose);

      final signedIn = await controller.submitSignIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(signedIn, isFalse);
      expect(controller.errorMessage, contains('Tidak dapat terhubung'));
    });

    test('notifies listeners while submitting and when done', () async {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      await controller.submitSignIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(notified, 2);
    });

    test('registering opens a session', () async {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      final registered = await controller.submitRegister(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
      );

      expect(registered, isTrue);
      expect(controller.account?.name, 'Budi Santoso');
    });

    test('a Google sign in opens a session', () async {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      final signedIn = await controller.submitGoogle();

      expect(signedIn, isTrue);
      expect(controller.account?.email, 'nadia@gmail.com');
      expect(controller.errorMessage, isNull);
    });

    test('a cancelled Google flow reports a failure', () async {
      final controller = build(
        _FakeAuthRepository(),
        google: _FakeGoogleIdentity(null),
      );
      addTearDown(controller.dispose);

      final signedIn = await controller.submitGoogle();

      expect(signedIn, isFalse);
      expect(controller.errorMessage, 'Login Google dibatalkan.');
    });

    test('a rejected Google token reports the server message', () async {
      final controller = build(_FakeAuthRepository(accepts: false));
      addTearDown(controller.dispose);

      final signedIn = await controller.submitGoogle();

      expect(signedIn, isFalse);
      expect(controller.errorMessage, 'Token Google tidak valid.');
    });

    test('signing out clears the account and the error', () async {
      final repository = _FakeAuthRepository(accepts: false);
      final controller = build(repository);
      addTearDown(controller.dispose);

      await controller.submitSignIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
      );
      await controller.submitSignOut();

      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, isNull);
      expect(repository.signOutCalls, 1);
    });

    test('clearError drops the message', () async {
      final controller = build(_FakeAuthRepository(accepts: false));
      addTearDown(controller.dispose);

      await controller.submitSignIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
      );
      controller.clearError();

      expect(controller.errorMessage, isNull);
    });

    test('clearError does not notify when there is no error', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      controller.clearError();

      expect(notified, 0);
    });

    test('restore adopts a session the repository already holds', () async {
      final repository = _FakeAuthRepository();
      await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );
      final controller = build(repository);
      addTearDown(controller.dispose);

      await controller.restore();

      expect(controller.isSignedIn, isTrue);
      expect(controller.account?.email, 'nadia@gmail.com');
    });

    test('restore stays signed out without a stored session', () async {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      await controller.restore();

      expect(controller.isSignedIn, isFalse);
    });
  });

  group('ProfileController', () {
    ProfileController build(_FakeAccountRepository repository) =>
        ProfileController(
          repository: repository,
          loadAccountStats: const LoadAccountStats(),
        );

    test('starts with empty stats', () {
      final controller = build(_FakeAccountRepository());
      addTearDown(controller.dispose);

      expect(controller.stats.totalScans, 0);
      expect(controller.stats.submittedReports, 0);
      expect(controller.stats.pendingReports, 0);
    });

    test('load fills the stats and notifies listeners', () async {
      final controller = build(_FakeAccountRepository());
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      await controller.load();

      expect(controller.stats.totalScans, 8);
      expect(controller.stats.submittedReports, 3);
      expect(controller.stats.pendingReports, 1);
      expect(notified, 2);
    });
  });

  group('SettingsController', () {
    SettingsController build(_FakeAccountRepository repository) =>
        SettingsController(
          repository: repository,
          setReportNotifications: const SetReportNotifications(),
        );

    test('load reads the stored preference', () async {
      final controller = build(
        _FakeAccountRepository()..notificationsEnabled = false,
      );
      addTearDown(controller.dispose);

      controller.load();

      expect(controller.reportNotificationsEnabled, isFalse);
    });

    test('toggling flips the preference and notifies listeners', () async {
      final controller = build(_FakeAccountRepository());
      addTearDown(controller.dispose);
      controller.load();

      var notified = 0;
      controller.addListener(() => notified++);

      final enabled = controller.toggleReportNotifications();

      expect(enabled, isFalse);
      expect(controller.reportNotificationsEnabled, isFalse);
      expect(notified, 1);
    });

    test('toggling twice restores the original value', () async {
      final repository = _FakeAccountRepository();
      final controller = build(repository);
      addTearDown(controller.dispose);
      controller.load();

      controller.toggleReportNotifications();
      final enabled = controller.toggleReportNotifications();

      expect(enabled, isTrue);
      expect(repository.notificationsEnabled, isTrue);
    });
  });
}
