import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service that loads and provides access to
/// environment variables from .env file
class EnvironmentConfig {
  static bool _isInitialized = false;

  /// Initialize the environment configuration by loading the .env file
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load();
      _isInitialized = true;
      print('Environment configuration loaded successfully');
    } catch (e) {
      print(
        'Warning: Could not load .env file. Some features may not work without '
        'required environment variables. Error: $e',
      );
      _isInitialized = true; // Continue but Auth0 getters will throw errors
    }
  }

  /// Ensure initialization before accessing any environment variables
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'EnvironmentConfig not initialized. Call EnvironmentConfig.initialize() first.',
      );
    }
  }

  // Auth0 Configuration - No defaults for security
  static String get auth0Domain {
    _ensureInitialized();
    final domain = dotenv.env['AUTH0_DOMAIN'];
    if (domain == null || domain.isEmpty) {
      throw StateError(
        'AUTH0_DOMAIN environment variable is required but not set. '
        'Please configure it in your .env file.',
      );
    }
    return domain;
  }

  static String get auth0ClientId {
    _ensureInitialized();
    final clientId = dotenv.env['AUTH0_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw StateError(
        'AUTH0_CLIENT_ID environment variable is required but not set. '
        'Please configure it in your .env file.',
      );
    }
    return clientId;
  }

  // API Configuration
  static String get apiBaseUrl {
    _ensureInitialized();
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
  }

  // App Configuration
  static String get appHostUrl {
    _ensureInitialized();
    return dotenv.env['APP_HOST_URL'] ?? 'http://localhost:5173';
  }

  // Environment
  static String get environment {
    _ensureInitialized();
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  // Utility methods
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  /// Get all environment variables as a map (for debugging)
  static Map<String, String> getAllVariables() {
    _ensureInitialized();
    return Map<String, String>.from(dotenv.env);
  }

  /// Validate that all required environment variables are set
  static bool validateRequiredVariables() {
    _ensureInitialized();
    try {
      // Test access to required Auth0 variables
      auth0Domain;
      auth0ClientId;
      return true;
    } catch (e) {
      print('Environment validation failed: $e');
      return false;
    }
  }
}
