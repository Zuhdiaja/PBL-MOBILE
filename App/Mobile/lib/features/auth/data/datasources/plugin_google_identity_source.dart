import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../config/google_config.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/repositories/google_identity_source.dart';

/// Asks the platform for a Google account and returns its tokens.
class PluginGoogleIdentitySource implements GoogleIdentitySource {
  PluginGoogleIdentitySource({GoogleSignIn? client})
    : _client =
          client ??
          (kIsWeb
              // The web implementation only understands clientId; passing a
              // serverClientId there makes Google Identity Services fail.
              ? GoogleSignIn(
                  clientId: googleWebClientId,
                  scopes: const ['email', 'profile'],
                )
              : GoogleSignIn(
                  serverClientId: googleWebClientId,
                  scopes: const ['email', 'profile'],
                )) {
    if (googleWebClientId.isEmpty) {
      throw StateError('GOOGLE_WEB_CLIENT_ID is not configured.');
    }
  }

  final GoogleSignIn _client;

  @override
  Future<GoogleTokens> obtainTokens() async {
    try {
      // On the web the popup flow returns an account without an ID token; a
      // silent follow-up re-reads the credential, and the access token is a
      // valid fallback the API can verify server-side.
      final account = await _client.signIn() ?? await _client.signInSilently();
      if (account == null) {
        debugPrint('Google sign-in: popup closed without an account');
        if (kDebugMode) {
          throw const AuthFailure(
            'Login Google gagal: popup tertutup tanpa akun',
          );
        }
        return const GoogleTokens();
      }
      var authentication = await account.authentication;
      if (authentication.idToken == null) {
        final silent = await _client.signInSilently();
        if (silent != null) authentication = await silent.authentication;
      }
      final tokens = GoogleTokens(
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
      );
      if (tokens.isEmpty) {
        debugPrint('Google sign-in: account present but no tokens');
        if (kDebugMode) {
          throw const AuthFailure(
            'Login Google gagal: akun ada tapi token kosong',
          );
        }
      }
      return tokens;
    } catch (error) {
      debugPrint('Google sign-in failed: $error');
      if (kDebugMode && error is! AuthFailure) {
        throw AuthFailure('Login Google gagal: $error');
      }
      rethrow;
    }
  }
}

/// Used when no client ID is configured; the button stays disabled.
class UnavailableGoogleIdentitySource implements GoogleIdentitySource {
  const UnavailableGoogleIdentitySource();

  @override
  Future<GoogleTokens> obtainTokens() async => const GoogleTokens();
}
