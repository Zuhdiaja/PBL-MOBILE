import 'package:google_sign_in/google_sign_in.dart';

import '../../../../config/google_config.dart';
import '../../domain/repositories/google_identity_source.dart';

/// Asks the platform for a Google account and returns its ID token.
class PluginGoogleIdentitySource implements GoogleIdentitySource {
  PluginGoogleIdentitySource({GoogleSignIn? client})
    : _client =
          client ??
          GoogleSignIn(
            clientId: googleWebClientId,
            serverClientId: googleWebClientId,
            scopes: const ['email', 'profile'],
          );

  final GoogleSignIn _client;

  @override
  Future<String?> obtainIdToken() async {
    final account = await _client.signIn();
    if (account == null) return null;
    final authentication = await account.authentication;
    return authentication.idToken;
  }
}

/// Used when no client ID is configured; the button stays disabled.
class UnavailableGoogleIdentitySource implements GoogleIdentitySource {
  const UnavailableGoogleIdentitySource();

  @override
  Future<String?> obtainIdToken() async => null;
}
