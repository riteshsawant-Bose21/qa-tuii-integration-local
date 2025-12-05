import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionAuthService {
  final Auth0 _auth0;
  final Auth0Web _auth0Web;
  final FusionSecureStorage _secureStorage;
  final String authScheme;
  final String webRedirectUrl;
  final String nativeRedirectUrl;

  FusionAuthService({
    required String domain,
    required String clientId,
    required FusionSecureStorage secureStorage,
    required this.authScheme,
    required this.webRedirectUrl,
    required this.nativeRedirectUrl,
  }) : _auth0 = Auth0(domain, clientId),
       _auth0Web = Auth0Web(domain, clientId),
       _secureStorage = secureStorage;

  /// Initialize web auth listener
  Future<Credentials?> initializeWebAuth() async {
    if (kIsWeb) {
      return await _auth0Web.onLoad();
    }
    return null;
  }

  /// Login
  Future<Credentials> login() async {
    if (kIsWeb) {
      await _auth0Web.loginWithRedirect(redirectUrl: webRedirectUrl);
      throw Exception('Web redirect initiated');
    }

    // Native login
    final Credentials credentials = await _auth0
        .webAuthentication(scheme: authScheme)
        .login(
          useHTTPS: false,
          redirectUrl: nativeRedirectUrl,
        );

    await _saveCredentials(credentials);
    return credentials;
  }

  /// Logout
  Future<void> logout() async {
    if (kIsWeb) {
      await _auth0Web.logout(returnToUrl: webRedirectUrl);
    } else {
      await _auth0
          .webAuthentication(scheme: authScheme)
          .logout(
            useHTTPS: false,
            returnTo: nativeRedirectUrl,
          );
    }

    await _clearCredentials();
  }

  /// Refresh access token using refresh token
  Future<Credentials> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('No refresh token available');
      }

      // Use Auth0 credentials manager to refresh
      final newCredentials = await _auth0.api.renewCredentials(refreshToken: refreshToken);

      await _saveCredentials(newCredentials);
      return newCredentials;
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Error refreshing access token: $e');
      // Clear invalid tokens
      await _clearCredentials();
      rethrow;
    }
  }

  /// Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    try {
      final expiresAtString = await _secureStorage.getToken(StorageKey.expiredAt);
      if (expiresAtString == null) return true;

      final expiresAt = DateTime.parse(expiresAtString);
      final now = DateTime.now();

      // Consider token expired if it expires in the next 5 minutes
      return now.isAfter(expiresAt.subtract(const Duration(minutes: 5)));
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Error checking token expiration: $e');
      return true;
    }
  }

  /// Get valid access token (refreshes if expired)
  Future<String?> getValidAccessToken() async {
    try {
      final isExpired = await isAccessTokenExpired();

      if (isExpired) {
        final hasRefreshToken = await getRefreshToken() != null;

        if (hasRefreshToken) {
          try {
            final newCredentials = await refreshAccessToken();
            return newCredentials.idToken;
          } catch (e) {
            FusionLogger.log(tag: LogTag.exceptions, message: 'Failed to refresh access token: $e');
            return null;
          }
        }
        return null;
      }

      return await getIdToken();
    } catch (e) {
      FusionLogger.log(tag: LogTag.exceptions, message: 'Error getting valid access token: $e');
      return null;
    }
  }

  /// Save credentials to secure storage
  Future<void> _saveCredentials(Credentials credentials) async {
    await _secureStorage.saveToken(
      StorageKey.accessToken,
      credentials.accessToken,
    );
    await _secureStorage.saveToken(
      StorageKey.idToken,
      credentials.idToken,
    );
    if (credentials.refreshToken != null) {
      await _secureStorage.saveToken(
        StorageKey.refreshToken,
        credentials.refreshToken!,
      );
    }
    // Save token expiration time
    await _secureStorage.saveToken(
      StorageKey.expiredAt,
      credentials.expiresAt.toIso8601String(),
    );

    // Save user info
    if (credentials.user.email != null) {
      await _secureStorage.saveToken(
        StorageKey.userEmail,
        credentials.user.email!,
      );
    }
    if (credentials.user.name != null) {
      await _secureStorage.saveToken(
        StorageKey.userName,
        credentials.user.name!,
      );
    }
  }

  /// Clear credentials from secure storage
  Future<void> _clearCredentials() async {
    await _secureStorage.clearAll();
  }

  /// Get stored credentials
  Future<String?> getAccessToken() async {
    return await _secureStorage.getToken(StorageKey.accessToken);
  }

  Future<String?> getIdToken() async {
    return await _secureStorage.getToken(StorageKey.idToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.getToken(StorageKey.refreshToken);
  }

  Future<String?> getUserEmail() async {
    return await _secureStorage.getToken(StorageKey.userEmail);
  }

  Future<String?> getUserName() async {
    return await _secureStorage.getToken(StorageKey.userName);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final String? accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
