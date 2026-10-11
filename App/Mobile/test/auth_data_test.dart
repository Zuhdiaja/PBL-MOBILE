import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/data/datasources/demo_account_data_source.dart';
import 'package:pbl_semester5/features/auth/data/datasources/demo_auth_data_source.dart';
import 'package:pbl_semester5/features/auth/data/repositories/account_repository_impl.dart';
import 'package:pbl_semester5/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late DemoAuthDataSource source;
    late AuthRepositoryImpl repository;

    setUp(() {
      source = DemoAuthDataSource();
      repository = AuthRepositoryImpl(source);
    });

    test('starts with no session', () {
      expect(repository.currentAccount(), isNull);
    });

    test('accepts the demo credentials and opens a session', () {
      final account = repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(account?.name, DemoAuthDataSource.demoName);
      expect(account?.email, DemoAuthDataSource.demoEmail);
      expect(repository.currentAccount()?.id, account?.id);
    });

    test('ignores the email casing and surrounding spaces', () {
      final account = repository.signIn(
        const SignInRequest(email: '  NADIA@Gmail.com ', password: '123456'),
      );

      expect(account, isNotNull);
    });

    test('rejects a wrong password', () {
      expect(
        repository.signIn(
          const SignInRequest(email: 'nadia@gmail.com', password: 'salah'),
        ),
        isNull,
      );
      expect(repository.currentAccount(), isNull);
    });

    test('rejects an unknown email', () {
      expect(
        repository.signIn(
          const SignInRequest(email: 'orang@email.com', password: '123456'),
        ),
        isNull,
      );
    });

    test('signing in twice keeps one session', () {
      repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );
      final account = repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      expect(repository.currentAccount()?.id, account?.id);
    });

    test('register creates an account that can sign in afterwards', () {
      final account = repository.register(
        const RegisterRequest(
          name: 'Budi Santoso',
          email: 'budi@email.com',
          password: 'rahasia',
        ),
      );

      expect(account.name, 'Budi Santoso');
      expect(account.initials, 'BS');

      repository.signOut();

      final signedIn = repository.signIn(
        const SignInRequest(email: 'budi@email.com', password: 'rahasia'),
      );
      expect(signedIn?.id, account.id);
    });

    test('registering with blank values falls back to the demo account', () {
      final account = repository.register(
        const RegisterRequest(name: '', email: '', password: ''),
      );

      expect(account.name, DemoAuthDataSource.demoName);
      expect(account.email, DemoAuthDataSource.demoEmail);
    });

    test('signing out clears the session', () {
      repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      repository.signOut();

      expect(repository.currentAccount(), isNull);
    });

    test('exposes the demo account used to prefill the login form', () {
      expect(repository.demoAccount.email, DemoAuthDataSource.demoEmail);
      expect(repository.demoAccount.name, DemoAuthDataSource.demoName);
    });

    test('data sources do not share sessions across instances', () {
      repository.signIn(
        const SignInRequest(email: 'nadia@gmail.com', password: '123456'),
      );

      final other = AuthRepositoryImpl(DemoAuthDataSource());

      expect(other.currentAccount(), isNull);
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
