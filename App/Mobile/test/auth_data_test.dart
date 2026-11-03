import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/data/datasources/demo_account_data_source.dart';
import 'package:pbl_semester5/features/auth/data/datasources/demo_auth_data_source.dart';
import 'package:pbl_semester5/features/auth/data/repositories/account_repository_impl.dart';
import 'package:pbl_semester5/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthRepositoryImpl with demo data', () {
    late DemoAuthDataSource source;
    late AuthRepositoryImpl repository;

    setUp(() {
      source = DemoAuthDataSource();
      repository = AuthRepositoryImpl(source);
    });

    test('starts with no session', () async {
      expect(await repository.currentAccount(), isNull);
    });

    test('accepts the demo credentials and opens a session', () async {
      final account = await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(account?.name, DemoAuthDataSource.demoName);
      expect(account?.email, DemoAuthDataSource.demoEmail);
      expect((await repository.currentAccount())?.id, account?.id);
    });

    test('ignores the email casing and surrounding spaces', () async {
      final account = await repository.signIn(
        const SignInRequest(email: '  NADIA@Gmail.com ', password: '123456'),
      );

      expect(account, isNotNull);
    });

    test('rejects a wrong password', () async {
      expect(
        await repository.signIn(
          const SignInRequest(email: 'nadia@gmail.com', password: 'salah'),
        ),
        isNull,
      );
      expect(await repository.currentAccount(), isNull);
    });

    test('rejects an unknown email', () async {
      expect(
        await repository.signIn(
          const SignInRequest(email: 'orang@email.com', password: '123456'),
        ),
        isNull,
      );
    });

    test('signing in twice keeps one session', () async {
      await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );
      final account = await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect((await repository.currentAccount())?.id, account?.id);
    });

    test('register creates an account that can sign in afterwards', () async {
      final account = await repository.register(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
      );

      expect(account.name, 'Budi Santoso');
      expect(account.initials, 'BS');

      await repository.signOut();

      final signedIn = await repository.signIn(
        const SignInRequest(
          email: 'budi@email.com',
          password: 'password-budi-2026',
        ),
      );
      expect(signedIn?.id, account.id);
    });

    test(
      'registering with blank values falls back to the demo account',
      () async {
        final account = await repository.register(
          const RegisterRequest(name: '', email: '', password: ''),
        );

        expect(account.name, DemoAuthDataSource.demoName);
        expect(account.email, DemoAuthDataSource.demoEmail);
      },
    );

    test('google sign in opens the demo session', () async {
      final account = await repository.signInWithGoogle('google-token');

      expect(account.email, DemoAuthDataSource.demoEmail);
    });

    test('signing out clears the session', () async {
      await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      await repository.signOut();

      expect(await repository.currentAccount(), isNull);
    });

    test('exposes the demo account used to prefill the login form', () {
      expect(repository.demoAccount?.email, DemoAuthDataSource.demoEmail);
      expect(repository.demoAccount?.name, DemoAuthDataSource.demoName);
    });

    test('data sources do not share sessions across instances', () async {
      await repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      final other = AuthRepositoryImpl(DemoAuthDataSource());

      expect(await other.currentAccount(), isNull);
    });
  });

  group('AccountRepositoryImpl', () {
    late DemoAccountDataSource source;
    late AccountRepositoryImpl repository;

    setUp(() {
      source = DemoAccountDataSource();
      repository = AccountRepositoryImpl(source);
    });

    test('reads the prototype counts', () {
      final stats = repository.readStats();

      expect(stats.totalScans, 8);
      expect(stats.submittedReports, 3);
      expect(stats.pendingReports, 1);
    });

    test('notifications start enabled', () {
      expect(repository.readReportNotificationsEnabled(), isTrue);
    });

    test('stores the notification preference', () {
      repository.writeReportNotificationsEnabled(false);

      expect(repository.readReportNotificationsEnabled(), isFalse);
    });

    test('a fresh data source returns to the default preference', () {
      repository.writeReportNotificationsEnabled(false);

      final other = AccountRepositoryImpl(DemoAccountDataSource());

      expect(other.readReportNotificationsEnabled(), isTrue);
    });
  });
}
