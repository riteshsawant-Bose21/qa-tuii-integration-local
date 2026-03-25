import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/core/config/auth0_config.dart';
import 'package:fusion_web/core/config/environment_config.dart';
import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/core/models/authorization_models.dart';
import 'package:fusion_web/core/services/service_locator.dart';
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
      print('Auth0 initialized with domain: ${Auth0Config.domain}');
      print(
        'Auth0 initialized with clientId: ${Auth0Config.clientId.substring(0, 8)}...',
      );
    } catch (e) {
      print('Failed to initialize Auth0: $e');
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
          print('Existing user data is valid JSON');
        } catch (e) {
          print('Invalid user data found, clearing...');
          html.window.localStorage.remove(_userKey);
        }
      }

      // Check if stored session data is valid JSON, if not clear it
      final sessionDataString = html.window.localStorage[_sessionKey];
      if (sessionDataString != null && sessionDataString.isNotEmpty) {
        try {
          jsonDecode(sessionDataString);
          print('Existing session data is valid JSON');
        } catch (e) {
          print('Invalid session data found, clearing...');
          html.window.localStorage.remove(_sessionKey);
        }
      }
    } catch (e) {
      print('Error validating stored data: $e');
    }
  }

  Future<UserEntity?> login() async {
    try {
      print('Starting Auth0 login...');

      // First check if user is already logged in
      final existingCredentials = await _auth0.onLoad();
      if (existingCredentials != null) {
        print('User already has valid session');
        await _storeSessionData(existingCredentials);
        return await getCurrentUser();
      }

      // Check manual session storage
      final storedSession = _getStoredSession();
      if (storedSession != null) {
        print('Found stored session, attempting to restore...');
        final user = _getStoredUser();
        if (user != null) {
          return user;
        }
      }

      print('No existing session, redirecting to Auth0...');
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
      print('Auth0 Login Error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('Logging out from Auth0...');

      // Clear API service token first
      _apiService.clearToken();

      // Clear manual session storage
      _clearStoredSession();

      // Try to logout from Auth0, but don't fail if Auth0 client has issues
      try {
        if (_isInitialized) {
          await _auth0.logout(returnToUrl: EnvironmentConfig.appHostUrl);
          print('Auth0 logout completed successfully');
        } else {
          print('Auth0 client not initialized, skipping Auth0 logout');
        }
      } catch (auth0Error) {
        print('Auth0 logout failed (continuing anyway): $auth0Error');
        // Don't throw - we've already cleared local data
      }
    } catch (e) {
      print('Logout error: $e');
      // Still clear local data even if Auth0 logout fails
      _apiService.clearToken();
      _clearStoredSession();
      throw Exception('Logout completed with warnings: ${e.toString()}');
    }
  }

  Future<String?> getIdToken() async {
    try {
      print('Getting ID token from Auth0...');

      // First check stored token
      final storedToken = _getStoredToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        print('Using stored ID token');
        return storedToken;
      }

      // Try multiple times with delays to give Auth0 time to restore session
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('Attempt $attempt to get credentials from Auth0...');

        final credentials = await _auth0.onLoad();
        final idToken = credentials?.idToken;

        print('Attempt $attempt - Auth0 credentials: ${credentials != null}');
        if (credentials != null) {
          print('Attempt $attempt - User: ${credentials.user.email}');
          print(
            'Attempt $attempt - Access Token: ${credentials.accessToken.isNotEmpty}',
          );
          print('Attempt $attempt - ID Token: ${idToken?.isNotEmpty ?? false}');

          if (idToken != null && idToken.isNotEmpty) {
            print('ID Token retrieved from Auth0 on attempt $attempt');

            // Store for future use
            await _storeSessionData(credentials);

            return idToken;
          }
        }

        // Wait longer between attempts
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      print('Failed to retrieve ID token from Auth0 after 3 attempts');
      return storedToken; // Return stored token as fallback
    } catch (e) {
      print('Error getting ID token: $e');
      return _getStoredToken();
    }
  }

  Future<AuthorizationResponse?> getAuthorizationInfo() async {
    try {
      print('Making authorization API call...');

      final token = await getIdToken();
      if (token == null) {
        throw Exception('No ID token available');
      }

      print('Setting bearer token for authorization API call');
      _apiService.setBearerToken(token);

      print('Calling GET /users/authorization');
      final response = await _apiService.get('/users/authorization');

      // Handle null response
      if (response.isEmpty) {
        throw Exception('Empty response from authorization endpoint');
      }

      print('Authorization API call completed successfully');
      return AuthorizationResponse.fromJson(response);
    } catch (e) {
      print('Authorization API Error: $e');
      throw Exception('Failed to get authorization info: $e');
    }
  }

  Future<UserEntity?> getCurrentUser() async {
    try {
      print('Getting current user...');

      // Check if we have a valid token (stored or from Auth0)
      final token = await getIdToken();

      if (token != null && token.isNotEmpty) {
        print('Valid token found, making authorization API call...');

        try {
          // Always try to get fresh user info from API first
          final authInfo = await getAuthorizationInfo();
          if (authInfo != null) {
            print('Authorization API call successful, got fresh user data');
            final user = authInfo.toUserEntity();
            _storeUser(user); // Update stored user with fresh data
            return user;
          }
        } catch (e) {
          print('Authorization API call failed: $e');
          // Fall back to Auth0 user data or stored data below
        }
      }

      // Try to get user data from Auth0 credentials
      final credentials = await _auth0.onLoad();
      if (credentials != null) {
        print('Auth0 Credentials Debug:');
        print('- User ID: ${credentials.user.sub}');
        print('- User Email: ${credentials.user.email}');

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
          print('Using Auth0 user data: ${user.email}');
          return user;
        }
      }

      // Final fallback to stored user data
      final storedUser = _getStoredUser();
      if (storedUser != null) {
        print('Using stored user as final fallback: ${storedUser.email}');
        return storedUser;
      }

      print('No user data available from any source');
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return _getStoredUser();
    }
  }

  Future<bool> isLoggedIn() async {
    if (!_isInitialized) {
      print('Auth0 not initialized, attempting to reinitialize...');
      _initializeAuth0();
      if (!_isInitialized) {
        print('Auth0 reinitialization failed');
        return false;
      }
    }

    try {
      print('Checking Auth0 login status...');

      // First check manual session storage
      final storedSession = _getStoredSession();
      if (storedSession != null) {
        print('Found stored session: $storedSession');
        final storedUser = _getStoredUser();
        if (storedUser != null) {
          print('Found stored user: ${storedUser.email}');
          return true;
        }
      }

      print('No stored session found, checking Auth0 SDK...');
      print('Current URL: ${Uri.base.toString()}');
      print('URL fragment: ${Uri.base.fragment}');

      // Check if this is a callback with tokens in URL fragment
      if (Uri.base.fragment.contains('access_token') ||
          Uri.base.fragment.contains('id_token')) {
        print('Detected Auth0 callback in URL fragment, processing...');
        await Future.delayed(const Duration(milliseconds: 2000));
      }

      // Try multiple times to get credentials from Auth0
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('Auth0 SDK check attempt $attempt...');

        try {
          final credentials = await _auth0.onLoad();

          if (credentials != null) {
            print('Attempt $attempt - Auth0 credentials found!');
            print('Attempt $attempt - User: ${credentials.user.email}');

            // Store session data for persistence
            await _storeSessionData(credentials);

            return true;
          } else {
            print('Attempt $attempt - No Auth0 credentials found');
          }
        } catch (e) {
          print('Attempt $attempt - Error: $e');
        }

        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      print('No valid session found after all attempts');
      return false;
    } catch (e) {
      print('Error checking login status: $e');
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

      print('Session data stored successfully');
    } catch (e) {
      print('Failed to store session data: $e');
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
      print('Invalid session data found, clearing: $e');
      try {
        html.window.localStorage.remove(_sessionKey);
      } catch (clearError) {
        print('Failed to clear session data: $clearError');
      }
      return null;
    }
  }

  String? _getStoredToken() {
    try {
      return html.window.localStorage[_tokenKey];
    } catch (e) {
      print('Failed to get stored token: $e');
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
      print('User data stored: ${user.email}');
    } catch (e) {
      print('Failed to store user data: $e');
    }
  }

  UserEntity? _getStoredUser() {
    try {
      final userDataString = html.window.localStorage[_userKey];
      if (userDataString == null || userDataString.isEmpty) {
        print('No stored user data found');
        return null;
      }

      print('Raw stored user data: $userDataString');

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

      print('Retrieved stored user: ${user.email}');
      return user;
    } catch (e) {
      print('Failed to get stored user (clearing invalid data): $e');
      // Clear invalid data and return null
      try {
        html.window.localStorage.remove(_userKey);
        print('Cleared invalid user data from storage');
      } catch (clearError) {
        print('Failed to clear invalid user data: $clearError');
      }
      return null;
    }
  }

  void _clearStoredSession() {
    try {
      html.window.localStorage.remove(_sessionKey);
      html.window.localStorage.remove(_tokenKey);
      html.window.localStorage.remove(_userKey);
      print('Stored session data cleared');
    } catch (e) {
      print('Failed to clear stored session: $e');
    }
  }

  // Helper method to clear all existing storage (useful for migration)
  void _clearAllStoredData() {
    try {
      final keysToRemove = <String>[];
      for (int i = 0; i < html.window.localStorage.length; i++) {
        final key = html.window.localStorage.keys.elementAt(i);
        if (key.startsWith('fusion_auth_')) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        html.window.localStorage.remove(key);
      }

      print('Cleared all fusion auth data from storage');
    } catch (e) {
      print('Failed to clear all stored data: $e');
    }
  }
}
