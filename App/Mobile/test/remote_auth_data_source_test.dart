import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/features/auth/data/datasources/remote_auth_data_source.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:pbl_semester5/features/auth/domain/entities/auth_failure.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object> _session({String email = 'nadia@example.com'}) => {
  'user': {'id': 7, 'name': 'Nadia Putri', 'email': email},
  'token': 'issued-token',
  'token_type': 'Bearer',
  'expires_in': 2592000,
};

RemoteAuthDataSource build(MockClient client, {TokenStore? tokenStore}) =>
    RemoteAuthDataSource(
      baseUrl: _baseUrl,
      tokenStore: tokenStore ?? MemoryTokenStore(),
      client: client,
    );

void main() {
  group('RemoteAuthDataSource', () {
    test('signIn stores the token and maps the account', () async {
      final store = MemoryTokenStore();
      final source = build(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$_baseUrl/api/v1/mobile/auth/login');
          expect(jsonDecode(request.body)['email'], 'nadia@example.com');
          return _json(_session(), 200);
        }),
        tokenStore: store,
      );

      final account = await source.signIn('nadia@example.com', 'password-2026');

      expect(account?.id, '7');
      expect(account?.name, 'Nadia Putri');
      expect(await store.read(), 'issued-token');
    });

    test('signIn maps 401 to a user facing failure', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'invalid_credentials',
              'message': 'Email atau password tidak sesuai.',
            },
          }, 401),
        ),
      );

      expect(
        () => source.signIn('nadia@example.com', 'salah'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Email atau password salah.',
          ),
        ),
      );
    });

    test('register maps 409 to a duplicate email failure', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'email_exists',
              'message': 'Email sudah terdaftar.',
            },
          }, 409),
        ),
      );

      expect(
        () => source.register('Nadia', 'nadia@example.com', 'password-2026'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('passes the server message through for other statuses', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'weak_password',
              'message': 'Password harus 12–256 karakter.',
            },
          }, 400),
        ),
      );

      expect(
        () => source.register('Nadia', 'nadia@example.com', 'pendek'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Password harus 12–256 karakter.',
          ),
        ),
      );
    });

    test('currentAccount returns null without a stored token', () async {
      var called = false;
      final source = build(
        MockClient((_) async {
          called = true;
          return _json({}, 500);
        }),
      );

      expect(await source.currentAccount(), isNull);
      expect(called, isFalse);
    });

    test('currentAccount restores the session from the token', () async {
      final source = build(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer stored-token');
          return _json({
            'user': {'id': 9, 'name': 'Nadia', 'email': 'n@example.com'},
          }, 200);
        }),
        tokenStore: MemoryTokenStore('stored-token'),
      );

      final account = await source.currentAccount();

      expect(account?.email, 'n@example.com');
    });

    test('currentAccount drops an expired token', () async {
      final store = MemoryTokenStore('expired-token');
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'unauthorized',
              'message': 'Silakan masuk kembali.',
            },
          }, 401),
        ),
        tokenStore: store,
      );

      expect(await source.currentAccount(), isNull);
      expect(await store.read(), isNull);
    });

    test(
      'signInWithGoogle stores the session from the google endpoint',
      () async {
        final store = MemoryTokenStore();
        final source = build(
          MockClient((request) async {
            expect(
              request.url.toString(),
              '$_baseUrl/api/v1/mobile/auth/google',
            );
            expect(jsonDecode(request.body)['id_token'], 'google-token');
            return _json(_session(email: 'nadia@gmail.com'), 200);
          }),
          tokenStore: store,
        );

        final account = await source.signInWithGoogle('google-token');

        expect(account.email, 'nadia@gmail.com');
        expect(await store.read(), 'issued-token');
      },
    );

    test('signInWithGoogle maps 503 to a configuration failure', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'google_unavailable',
              'message': 'Login Google belum dikonfigurasi.',
            },
          }, 503),
        ),
      );

      expect(
        () => source.signInWithGoogle('google-token'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Login Google belum dikonfigurasi.',
          ),
        ),
      );
    });

    test('network errors become a friendly failure', () async {
      final source = build(MockClient((_) async => throw Exception('offline')));

      expect(
        () => source.signIn('nadia@example.com', 'password-2026'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });

    test('signOut clears the token even when the request fails', () async {
      final store = MemoryTokenStore('stored-token');
      final source = build(
        MockClient((_) async => throw Exception('offline')),
        tokenStore: store,
      );

      await source.signOut();

      expect(await store.read(), isNull);
    });
  });
}
