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

  /// When set, every call throws this failure as the API would.
  AuthFailure? failure;

  @override
  Future<UserAccount?> currentAccount() async => _session;

  @override
  Future<UserAccount> register(RegisterRequest request) async {
    if (failure != null) throw failure!;
    lastRegistration = request;
    _session = UserAccount(
      id: 'registered-1',
      name: request.name,
      email: request.email,
    );
    return _session!;
  }

  @override
  Future<UserAccount> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    if (failure != null) throw failure!;
    _session = const UserAccount(
      id: 'google-1',
      name: 'Nadia Google',
      email: 'nadia@gmail.com',
    );
    return _session!;
  }

  @override
  Future<UserAccount?> signIn(SignInRequest request) async {
    if (failure != null) throw failure!;
    if (!accepts) return null;
    _session = demoAccount;
    return _session;
  }

  @override
  Future<void> signOut() async => _session = null;
}

class _FakeGoogleIdentity implements GoogleIdentitySource {
  _FakeGoogleIdentity(this.token);

  final String? token;

  @override
  Future<GoogleTokens> obtainTokens() async => GoogleTokens(idToken: token);
}

class _ThrowingGoogleIdentity implements GoogleIdentitySource {
  @override
  Future<GoogleTokens> obtainTokens() async =>
      throw StateError('plugin missing');
}

class _FailingGoogleIdentity implements GoogleIdentitySource {
  @override
  Future<GoogleTokens> obtainTokens() async =>
      throw const AuthFailure('Login Google gagal: detail teknis');
}

class _FakeAccountRepository implements AccountRepository {
  bool notificationsEnabled = true;

  @override
  AccountStats readStats() =>
      const AccountStats(totalScans: 8, submittedReports: 3, pendingReports: 1);

  @override
  Future<bool> readReportNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> writeReportNotificationsEnabled(bool enabled) async =>
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

    test('opens a session for valid credentials', () async {
      final repository = _FakeAuthRepository();

      final result = await signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
        repository,
      );

      expect(result.account, demoAccount);
      expect(result.failure, isNull);
    });

    test('trims the email before validating it', () async {
      final repository = _FakeAuthRepository();

      final result = await signIn(
        const SignInRequest(email: '  nadia@gmail.com  ', password: '123456'),
        repository,
      );

      expect(result.account, isNotNull);
    });

    test('turns rejected credentials into a user facing failure', () async {
      final repository = _FakeAuthRepository(accepts: false);

      final result = await signIn(
        const SignInRequest(email: 'salah@email.com', password: 'salah'),
        repository,
      );

      expect(result.account, isNull);
      expect(result.failure?.message, 'Email atau password salah.');
    });

    test('passes the server message through', () async {
      final repository = _FakeAuthRepository()
        ..failure = const AuthFailure('Email atau password salah.');

      final result = await signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: 'salah'),
        repository,
      );

      expect(result.failure?.message, 'Email atau password salah.');
    });

    test('rejects an empty email without touching the repository', () async {
      final repository = _FakeAuthRepository();

      final result = await signIn(
        const SignInRequest(email: '   ', password: '123456'),
        repository,
      );

      expect(result.account, isNull);
      expect(result.failure?.message, contains('wajib diisi'));
      expect(await repository.currentAccount(), isNull);
    });

    test('rejects an empty password', () async {
      final result = await signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: ''),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('wajib diisi'));
    });
  });

  group('RegisterAccount', () {
    const register = RegisterAccount();

    test('creates an account and opens a session', () async {
      final repository = _FakeAuthRepository();

      final result = await register(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
        repository,
      );

      expect(result.account?.name, 'Budi Santoso');
      expect(result.account?.email, 'budi@email.com');
      expect(result.failure, isNull);
      expect(await repository.currentAccount(), result.account);
    });

    test('trims whitespace off the submitted values', () async {
      final repository = _FakeAuthRepository();

      await register(
        const RegisterRequest(
          name: '  Budi  ',
          email: '  budi@email.com  ',
          password: 'password-budi-2026',
        ),
        repository,
      );

      expect(repository.lastRegistration?.name, 'Budi');
      expect(repository.lastRegistration?.email, 'budi@email.com');
    });

    test('rejects a blank name', () async {
      final result = await register(
        const RegisterRequest(
          name: '  ',
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, 'Nama wajib diisi.');
    });

    test('rejects an invalid email', () async {
      final result = await register(
        const RegisterRequest(
          name: 'Budi',
          email: 'budi',
          password: 'password-budi-2026',
        ),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('email yang valid'));
    });

    test('rejects a password shorter than the API minimum', () async {
      final result = await register(
        const RegisterRequest(
          name: 'Budi',
          email: 'budi@email.com',
          password: 'pendek',
        ),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('minimal 12'));
    });

    test('passes a duplicate email failure through', () async {
      final repository = _FakeAuthRepository()
        ..failure = const AuthFailure('Email sudah terdaftar. Silakan masuk.');

      final result = await register(
        const RegisterRequest(
          name: 'Budi',
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
        repository,
      );

      expect(result.failure?.message, contains('sudah terdaftar'));
    });
  });

  group('SignInWithGoogle', () {
    const signInWithGoogle = SignInWithGoogle();

    test('exchanges a platform token for a session', () async {
      final repository = _FakeAuthRepository();

      final result = await signInWithGoogle(
        _FakeGoogleIdentity('google-token'),
        repository,
      );

      expect(result.account?.email, 'nadia@gmail.com');
      expect(result.failure, isNull);
    });

    test('a cancelled chooser becomes a user facing failure', () async {
      final result = await signInWithGoogle(
        _FakeGoogleIdentity(null),
        _FakeAuthRepository(),
      );

      expect(result.account, isNull);
      expect(result.failure?.message, 'Login Google dibatalkan.');
    });

    test('a plugin error becomes a user facing failure', () async {
      final result = await signInWithGoogle(
        _ThrowingGoogleIdentity(),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('tidak dapat dimulai'));
    });

    test('an identity source failure keeps its own message', () async {
      final result = await signInWithGoogle(
        _FailingGoogleIdentity(),
        _FakeAuthRepository(),
      );

      expect(result.failure?.message, contains('detail teknis'));
    });

    test('server rejections are passed through', () async {
      final repository = _FakeAuthRepository()
        ..failure = const AuthFailure(
          'Email ini sudah tertaut ke akun Google lain.',
        );

      final result = await signInWithGoogle(
        _FakeGoogleIdentity('google-token'),
        repository,
      );

      expect(result.failure?.message, contains('sudah tertaut'));
    });
  });

  group('SignOut', () {
    const signOut = SignOut();

    test('clears the stored session', () async {
      final repository = _FakeAuthRepository();
      await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      await signOut(repository);

      expect(await repository.currentAccount(), isNull);
    });
  });

  group('LoadAccountStats', () {
    const loadStats = LoadAccountStats();

    test('reads the counts through the repository', () async {
      final stats = await loadStats(_FakeAccountRepository());

      expect(stats.totalScans, 8);
      expect(stats.submittedReports, 3);
      expect(stats.pendingReports, 1);
    });
  });

  group('SetReportNotifications', () {
    const setNotifications = SetReportNotifications();

    test('persists the preference and returns the stored value', () async {
      final repository = _FakeAccountRepository();

      final stored = await setNotifications(false, repository);

      expect(stored, isFalse);
      expect(repository.notificationsEnabled, isFalse);
    });

    test('turning the preference back on is reported', () async {
      final repository = _FakeAccountRepository();

      expect(await setNotifications(true, repository), isTrue);
      expect(repository.notificationsEnabled, isTrue);
    });
  });

  group('AuthFailure', () {
    test('carries the message shown to the user', () {
      expect(const AuthFailure('Gagal.').message, 'Gagal.');
    });
  });
}
