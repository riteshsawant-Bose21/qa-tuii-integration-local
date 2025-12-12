import 'package:flutter_dotenv/flutter_dotenv.dart';

// App-specific configuration
class AppConfig {
  static late final String auth0Domain;
  static late final String auth0ClientId;
  static late final String auth0RedirectUri;
  static late final String auth0NativeRedirectUri;
  static late final String auth0Schema;
  static late final String awsApiBaseUrl;

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    auth0Domain = dotenv.env['AUTH0_DOMAIN'] ?? '';
    auth0ClientId = dotenv.env['AUTH0_CLIENT_ID'] ?? '';
    auth0RedirectUri = dotenv.env['AUTH0_REDIRECT_URI'] ?? '';
    auth0NativeRedirectUri = dotenv.env['AUTH0_NATIVE_REDIRECT_URI'] ?? '';
    auth0Schema = dotenv.env['AUTH0_SCHEMA'] ?? '';
    awsApiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

    _validateConfig();
  }

  static void _validateConfig() {
    if (auth0Domain.isEmpty || auth0ClientId.isEmpty) {
      throw Exception('Missing required Auth0 configuration');
    }
  }
}
