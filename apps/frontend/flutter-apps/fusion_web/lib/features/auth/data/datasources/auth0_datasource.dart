import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/core/config/auth0_config.dart';
import 'package:fusion_web/core/config/environment_config.dart';
import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/core/models/authorization_models.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/permissions/permission_service.dart';
import 'dart:html' as html;
import 'dart:convert';

class Auth0DataSource {
  late final Auth0Web _auth0;
  final ApiService _apiService;
  bool _isInitialized = false;

  // Manual session storage keys
  static const String _sessionKey = 'fusion_auth_session';
  static const String _userKey = 'fusion_auth_user';
  static const String _tokenKey = 'fusion_auth_token';

  Auth0DataSource({ApiService? apiService})
    : _apiService = apiService ?? ServiceLocator().apiService {
    _initializeAuth0();
  }

  void _initializeAuth0() {
    try {
      // Clear any invalid stored data from previous versions
      _validateAndCleanStoredData();

      _auth0 = Auth0Web(Auth0Config.domain, Auth0Config.clientId);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  void _validateAndCleanStoredData() {
    try {
      // Check if stored user data is valid JSON, if not clear it
      final userDataString = html.window.localStorage[_userKey];
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          jsonDecode(userDataString);
        } catch (e) {
          html.window.localStorage.remove(_userKey);
        }
      }

      // Check if stored session data is valid JSON, if not clear it
      final sessionDataString = html.window.localStorage[_sessionKey];
      if (sessionDataString != null && sessionDataString.isNotEmpty) {
        try {
          jsonDecode(sessionDataString);
        } catch (e) {
          html.window.localStorage.remove(_sessionKey);
        }
      }
    } catch (e) {
      // Ignore validation errors
    }
  }

  Future<UserEntity?> login() async {
    try {
      // First check if user is already logged in
      final existingCredentials = await _auth0.onLoad();
      if (existingCredentials != null) {
        await _storeSessionData(existingCredentials);
        return await getCurrentUser();
      }

      // Check manual session storage
      final storedSession = _getStoredSession();
      if (storedSession != null) {
        final user = _getStoredUser();
        if (user != null) {
          return user;
        }
      }

      await _auth0.loginWithRedirect(
        redirectUrl: EnvironmentConfig.appHostUrl,
        parameters: {
          'scope': 'openid profile email',
          'response_type': 'id_token token',
        },
      );

      // The method returns after redirect, so we need to check credentials in onLoad
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Clear API service token first
      _apiService.clearToken();

      // Clear manual session storage
      _clearStoredSession();

      // Clear permission service data
      PermissionService.instance.clear();

      // Try to logout from Auth0, but don't fail if Auth0 client has issues
      try {
        if (_isInitialized) {
          await _auth0.logout(returnToUrl: EnvironmentConfig.appHostUrl);
        }
      } catch (auth0Error) {
        // Don't throw - we've already cleared local data
      }
    } catch (e) {
      // Still clear local data even if Auth0 logout fails
      _apiService.clearToken();
      _clearStoredSession();
      PermissionService.instance.clear();
      throw Exception('Logout completed with warnings: ${e.toString()}');
    }
  }

  Future<String?> getIdToken() async {
    try {
      // First try to get fresh token from Auth0
      for (int attempt = 1; attempt <= 3; attempt++) {
        final credentials = await _auth0.onLoad();
        final idToken = credentials?.idToken;

        if (credentials != null && idToken != null && idToken.isNotEmpty) {
          // Validate token is not expired by trying to decode it
          if (_isTokenValid(idToken)) {
            // Store for future use
            await _storeSessionData(credentials);
            return idToken;
          } else {
            print('⚠️ Auth0DataSource: Token from Auth0 is expired');
            _clearStoredSession();
            return null;
          }
        }

        // Wait between attempts
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      // Fallback: check stored token and validate it
      final storedToken = _getStoredToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        if (_isTokenValid(storedToken)) {
          return storedToken;
        } else {
          print('⚠️ Auth0DataSource: Stored token is expired, clearing');
          _clearStoredSession();
          return null;
        }
      }

      return null;
    } catch (e) {
      print('❌ Auth0DataSource: Error getting token: $e');
      // Check stored token as last resort
      final storedToken = _getStoredToken();
      if (storedToken != null && _isTokenValid(storedToken)) {
        return storedToken;
      }
      _clearStoredSession();
      return null;
    }
  }

  bool _isTokenValid(String token) {
    try {
      // Basic JWT structure validation
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      // Decode the payload to check expiration
      final payload = parts[1];
      // Add padding if needed
      var normalizedPayload = payload;
      switch (payload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      // Check expiration
      final exp = payloadMap['exp'] as int?;
      if (exp == null) {
        print('⚠️ Token has no expiration claim');
        return false; // No expiration claim, consider invalid
      }

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final isValid = expirationTime.isAfter(now);

      if (!isValid) {
        print('⚠️ Token expired at $expirationTime, now is $now');
      }

      return isValid;
    } catch (e) {
      print('❌ Error validating token: $e');
      return false;
    }
  }

  Future<AuthorizationResponse?> getAuthorizationInfo() async {
    try {
      final token = await getIdToken();
      if (token == null) {
        throw Exception('No ID token available');
      }

      _apiService.setBearerToken(token);
      final response = await _apiService.get('/users/authorization');

      // Handle null response
      if (response.isEmpty) {
        throw Exception('Empty response from authorization endpoint');
      }

      return AuthorizationResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get authorization info: $e');
    }
  }

  Future<UserEntity?> getCurrentUser() async {
    try {
      // Check if we have a valid token (stored or from Auth0)
      final token = await getIdToken();

      if (token != null && token.isNotEmpty) {
        try {
          // Always try to get fresh user info from API first
          final authInfo = await getAuthorizationInfo();
          if (authInfo != null) {
            // Initialize the permission service with the authorization data
            PermissionService.instance.initialize(authInfo);

            final user = authInfo.toUserEntity();
            _storeUser(user); // Update stored user with fresh data
            return user;
          }
        } catch (e) {
          // Fall back to Auth0 user data or stored data below
        }
      }

      // Try to get user data from Auth0 credentials
      final credentials = await _auth0.onLoad();
      if (credentials != null) {
        // Store credentials for persistence
        await _storeSessionData(credentials);

        if (credentials.user.email != null) {
          // Fallback to Auth0 user data
          final user = UserEntity(
            id: credentials.user.sub,
            email: credentials.user.email!,
            name: credentials.user.name ?? 'User',
            picture: credentials.user.pictureUrl?.toString(),
          );

          _storeUser(user);
          return user;
        }
      }

      // Final fallback to stored user data
      final storedUser = _getStoredUser();
      if (storedUser != null) {
        return storedUser;
      }

      return null;
    } catch (e) {
      return _getStoredUser();
    }
  }

  Future<bool> isLoggedIn() async {
    if (!_isInitialized) {
      _initializeAuth0();
      if (!_isInitialized) {
        return false;
      }
    }

    try {
      // First check manual session storage
      final storedSession = _getStoredSession();
      if (storedSession != null) {
        final storedUser = _getStoredUser();
        if (storedUser != null) {
          return true;
        }
      }

      // Check if this is a callback with tokens in URL fragment
      if (Uri.base.fragment.contains('access_token') ||
          Uri.base.fragment.contains('id_token')) {
        await Future.delayed(const Duration(milliseconds: 2000));
      }

      // Try multiple times to get credentials from Auth0
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final credentials = await _auth0.onLoad();

          if (credentials != null) {
            // Store session data for persistence
            await _storeSessionData(credentials);
            return true;
          }
        } catch (e) {
          // Continue to next attempt
        }

        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Manual session storage helper methods
  Future<void> _storeSessionData(credentials) async {
    try {
      final sessionData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userEmail': credentials.user.email,
        'userId': credentials.user.sub,
      };

      html.window.localStorage[_sessionKey] = jsonEncode(sessionData);
      html.window.localStorage[_tokenKey] = credentials.idToken ?? '';
    } catch (e) {
      // Failed to store session data
    }
  }

  String? _getStoredSession() {
    try {
      final sessionData = html.window.localStorage[_sessionKey];
      if (sessionData == null || sessionData.isEmpty) return null;

      // Validate it's proper JSON by trying to decode
      jsonDecode(sessionData);
      return sessionData;
    } catch (e) {
      try {
        html.window.localStorage.remove(_sessionKey);
      } catch (clearError) {
        // Failed to clear session data
      }
      return null;
    }
  }

  String? _getStoredToken() {
    try {
      return html.window.localStorage[_tokenKey];
    } catch (e) {
      return null;
    }
  }

  void _storeUser(UserEntity user) {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.name ?? '',
        'picture': user.picture ?? '',
      };
      html.window.localStorage[_userKey] = jsonEncode(userData);
    } catch (e) {
      // Failed to store user data
    }
  }

  UserEntity? _getStoredUser() {
    try {
      final userDataString = html.window.localStorage[_userKey];
      if (userDataString == null || userDataString.isEmpty) {
        return null;
      }

      // Try to parse as JSON
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      final user = UserEntity(
        id: userData['id'] ?? '',
        email: userData['email'] ?? '',
        name: userData['name']?.isEmpty == true ? 'User' : userData['name'],
        picture: userData['picture']?.isEmpty == true
            ? null
            : userData['picture'],
      );

      return user;
    } catch (e) {
      // Clear invalid data and return null
      try {
        html.window.localStorage.remove(_userKey);
      } catch (clearError) {
        // Failed to clear invalid user data
      }
      return null;
    }
  }

  void _clearStoredSession() {
    try {
      html.window.localStorage.remove(_sessionKey);
      html.window.localStorage.remove(_tokenKey);
      html.window.localStorage.remove(_userKey);
    } catch (e) {
      // Failed to clear stored session
    }
  }
}
