import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/domain/entities/user_account.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/account_repository.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/load_account_stats.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/register_account.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/set_report_notifications.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_in.dart';
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
  UserAccount? currentAccount() => _session;

  @override
  UserAccount register(RegisterRequest request) {
    _session = UserAccount(
      id: 'registered-1',
      name: request.name.isEmpty ? 'Nadia Putri' : request.name,
      email: request.email.isEmpty ? 'nadia@gmail.com' : request.email,
    );
    return _session!;
  }

  @override
  UserAccount? signIn(SignInRequest request) {
    if (!accepts) return null;
    return _session = const UserAccount(
      id: 'demo-1',
      name: 'Nadia Putri',
      email: 'nadia@gmail.com',
    );
  }

  @override
  void signOut() {
    signOutCalls++;
    _session = null;
  }
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
    AuthController build(_FakeAuthRepository repository) => AuthController(
      repository: repository,
      signIn: const SignIn(),
      registerAccount: const RegisterAccount(),
      signOut: const SignOut(),
    );

    test('starts signed out with no error', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      expect(controller.isSignedIn, isFalse);
      expect(controller.account, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('a successful sign in exposes the account', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      final signedIn = controller.submitSignIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(signedIn, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.account?.name, 'Nadia Putri');
      expect(controller.errorMessage, isNull);
    });

    test('a rejected sign in keeps the error message', () {
      final controller = build(_FakeAuthRepository(accepts: false));
      addTearDown(controller.dispose);

      final signedIn = controller.submitSignIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
      );

      expect(signedIn, isFalse);
      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, 'Email atau password salah.');
    });

    test('notifies listeners when the outcome changes', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      controller.submitSignIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(notified, 1);
    });

    test('registering opens a session', () {
      final controller = build(_FakeAuthRepository());
      addTearDown(controller.dispose);

      final registered = controller.submitRegister(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'rahasia',
        ),
      );

      expect(registered, isTrue);
      expect(controller.account?.name, 'Budi Santoso');
    });

    test('signing out clears the account and the error', () {
      final repository = _FakeAuthRepository(accepts: false);
      final controller = build(repository);
      addTearDown(controller.dispose);

      controller.submitSignIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
      );
      controller.submitSignOut();

      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, isNull);
      expect(repository.signOutCalls, 1);
    });

    test('clearError drops the message', () {
      final controller = build(_FakeAuthRepository(accepts: false));
      addTearDown(controller.dispose);

      controller.submitSignIn(
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
      final repository = _FakeAuthRepository()
        ..signIn(
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
