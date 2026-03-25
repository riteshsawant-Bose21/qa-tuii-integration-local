import 'package:fusion_web/core/config/environment_config.dart';

/// Auth0 Configuration
/// This configuration now uses environment variables for sensitive data.
/// Make sure to configure your Auth0 application settings:
/// - Allowed Callback URLs: {APP_HOST_URL}
/// - Allowed Logout URLs: {APP_HOST_URL}
/// - Allowed Web Origins: {APP_HOST_URL}
class Auth0Config {
  static String get domain => EnvironmentConfig.auth0Domain;
  static String get clientId => EnvironmentConfig.auth0ClientId;
}
