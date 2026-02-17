import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:fusion_web/features/auth/domain/entities/user_entity.dart';
import 'package:fusion_web/core/config/auth0_config.dart';
import 'package:fusion_web/core/config/environment_config.dart';
import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/core/models/authorization_models.dart';
import 'package:fusion_web/core/services/service_locator.dart';

class Auth0DataSource {
  late final Auth0Web _auth0;
  final ApiService _apiService;

  Auth0DataSource({ApiService? apiService})
    : _apiService = apiService ?? ServiceLocator().apiService {
    _auth0 = Auth0Web(Auth0Config.domain, Auth0Config.clientId);
  }

  Future<UserEntity?> login() async {
    try {
      print('Starting Auth0 login...');

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
      _apiService.clearToken();
      await _auth0.logout(returnToUrl: EnvironmentConfig.appHostUrl);
    } catch (e) {
      print('Auth0 Logout Error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  Future<String?> getIdToken() async {
    try {
      final credentials = await _auth0.onLoad();
      final idToken = credentials?.idToken;
      print('Auth0 ID Token available: ${idToken != null}');
      if (idToken != null) {
        print('ID Token length: ${idToken.length}');
        print('ID Token preview: ${idToken.substring(0, 50)}...');
      }
      return idToken;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  Future<AuthorizationResponse?> getAuthorizationInfo() async {
    try {
      final token = await getIdToken();
      if (token == null) {
        throw Exception('No ID token available');
      }

      _apiService.setBearerToken(token);
      final response = await _apiService.get('users/authorization');

      // Handle null response
      if (response.isEmpty) {
        throw Exception('Empty response from authorization endpoint');
      }

      return AuthorizationResponse.fromJson(response);
    } catch (e) {
      print('Authorization API Error: $e');
      throw Exception('Failed to get authorization info: $e');
    }
  }

  Future<UserEntity?> getCurrentUser() async {
    try {
      final credentials = await _auth0.onLoad();

      // Debug credentials
      if (credentials != null) {
        print('Auth0 Credentials Debug:');
        print('- User ID: ${credentials.user.sub}');
        print('- User Email: ${credentials.user.email}');
        print('- Access Token available: ${credentials.accessToken != null}');
        print('- ID Token available: ${credentials.idToken != null}');
        if (credentials.accessToken != null) {
          print('- Access Token length: ${credentials.accessToken!.length}');
        }
        if (credentials.idToken != null) {
          print('- ID Token length: ${credentials.idToken!.length}');
        }
      }

      if (credentials != null && credentials.user.email != null) {
        try {
          // Try to get full user info from API
          final authInfo = await getAuthorizationInfo();
          if (authInfo != null) {
            return authInfo.toUserEntity();
          }
        } catch (e) {
          print('Failed to get authorization info, using Auth0 user data: $e');
        }

        // Fallback to Auth0 user data
        return UserEntity(
          id: credentials.user.sub,
          email: credentials.user.email!,
          name: credentials.user.name ?? 'User',
          picture: credentials.user.pictureUrl?.toString(),
        );
      }

      return null;
    } catch (e) {
      // User not logged in
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final credentials = await _auth0.onLoad();
      return credentials != null;
    } catch (e) {
      return false;
    }
  }
}
