import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/domain/entities/auth_failure.dart';
import 'package:pbl_semester5/features/auth/domain/entities/user_account.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/account_repository.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/load_account_stats.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/register_account.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/set_report_notifications.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_in.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/sign_out.dart';

const demoAccount = UserAccount(
  id: 'demo-1',
  name: 'Nadia Putri',
  email: 'nadia@gmail.com',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.accepts = true});

  /// Whether sign in accepts the submitted credentials.
  final bool accepts;

  UserAccount? _session;
  RegisterRequest? lastRegistration;

  @override
  UserAccount? currentAccount() => _session;

  @override
  UserAccount register(RegisterRequest request) {
    lastRegistration = request;
    _session = UserAccount(
      id: 'registered-1',
      name: request.name,
      email: request.email,
    );
    return _session!;
  }

  @override
  UserAccount? signIn(SignInRequest request) {
    if (!accepts) return null;
    _session = demoAccount;
    return _session;
  }

  @override
  void signOut() => _session = null;
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
  group('UserAccount', () {
    test('derives initials from the first two words', () {
      expect(demoAccount.initials, 'NP');
    });

    test('falls back to a single initial for a one word name', () {
      const account = UserAccount(id: '1', name: 'Nadia', email: 'a@b.test');

      expect(account.initials, 'N');
    });

    test('falls back to a placeholder for a blank name', () {
      const account = UserAccount(id: '1', name: '   ', email: 'a@b.test');

      expect(account.initials, '?');
      expect(account.firstName, '   ');
    });

    test('firstName drops everything after the first space', () {
      expect(demoAccount.firstName, 'Nadia');
    });
  });

  group('SignIn', () {
    const signIn = SignIn();

    test('opens a session for valid credentials', () {
      final repository = _FakeAuthRepository();

      final result = signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
        repository,
      );

      expect(result.account, demoAccount);
      expect(result.failure, isNull);
    });

    test('trims the email before validating it', () {
      final repository = _FakeAuthRepository();

      final result = signIn(
        const SignInRequest(email: '  nadia@gmail.com  ', password: '123456'),
        repository,
      );

      expect(result.account, isNotNull);
    });

    test('turns rejected credentials into a user facing failure', () {
      final repository = _FakeAuthRepository(accepts: false);

      final result = signIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
        repository,
      );

      expect(result.account, isNull);
      expect(result.failure?.message, 'Email atau password salah.');
    });

    test('rejects an empty email without touching the repository', () {
      final repository = _FakeAuthRepository();

      final result = signIn(
        const SignInRequest(email: '   ', password: '123456'),
        repository,
      );

      expect(result.account, isNull);
      expect(result.failure?.message, contains('wajib diisi'));
      expect(repository.currentAccount(), isNull);
    });

    test('rejects an empty password', () {
      final result = signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: ''),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('wajib diisi'));
    });
  });

  group('RegisterAccount', () {
    const register = RegisterAccount();

    test('creates an account and opens a session', () {
      final repository = _FakeAuthRepository();

      final result = register(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'rahasia',
        ),
        repository,
      );

      expect(result.account?.name, 'Budi Santoso');
      expect(result.account?.email, 'budi@email.com');
      expect(result.failure, isNull);
      expect(repository.currentAccount(), result.account);
    });

    test('trims whitespace off the submitted values', () {
      final repository = _FakeAuthRepository();

      register(
        const RegisterRequest(
          name: '  Budi  ',
          email: '  budi@email.com  ',
          password: 'rahasia',
        ),
        repository,
      );

      expect(repository.lastRegistration?.name, 'Budi');
      expect(repository.lastRegistration?.email, 'budi@email.com');
    });
  });

  group('SignOut', () {
    const signOut = SignOut();

    test('clears the stored session', () {
      final repository = _FakeAuthRepository()
        ..signIn(
          const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
        );

      signOut(repository);

      expect(repository.currentAccount(), isNull);
    });
  });

  group('LoadAccountStats', () {
    const loadStats = LoadAccountStats();

    test('reads the counts through the repository', () {
      final stats = loadStats(_FakeAccountRepository());

      expect(stats.totalScans, 8);
      expect(stats.submittedReports, 3);
      expect(stats.pendingReports, 1);
    });
  });

  group('SetReportNotifications', () {
    const setNotifications = SetReportNotifications();

    test('persists the preference and returns the stored value', () {
      final repository = _FakeAccountRepository();

      final stored = setNotifications(false, repository);

      expect(stored, isFalse);
      expect(repository.notificationsEnabled, isFalse);
    });

    test('turning the preference back on is reported', () {
      final repository = _FakeAccountRepository();

      expect(setNotifications(true, repository), isTrue);
      expect(repository.notificationsEnabled, isTrue);
    });
  });

  group('AuthFailure', () {
    test('carries the message shown to the user', () {
      expect(const AuthFailure('Gagal.').message, 'Gagal.');
    });
  });
}
