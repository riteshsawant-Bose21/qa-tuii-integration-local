import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/config/environment_config.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvironmentConfig.initialize();

  // Validate required environment variables
  if (!EnvironmentConfig.validateRequiredVariables()) {
    print(
      '❌ Application cannot start due to missing required environment variables.',
    );
    print(
      'Please check your .env file and ensure all required variables are set.',
    );
    return;
  }

  // Initialize authentication token on app start
  await _initializeAuthToken();

  runApp(const MyApp());
}

Future<void> _initializeAuthToken() async {
  try {
    final dataSource = Auth0DataSource();
    final repository = AuthRepositoryImpl(dataSource: dataSource);

    // Check if user is logged in and restore token
    final isLoggedIn = await repository.isLoggedIn();
    if (isLoggedIn) {
      final token = await repository.getIdToken();
      if (token != null) {
        ServiceLocator().apiService.setBearerToken(token);
        print('🔐 Auth token restored on app startup');
      }
    }
  } catch (e) {
    print('⚠️ Failed to restore auth token on startup: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: FusionAppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.montserratTextTheme(
          FusionAppTheme.lightTheme.textTheme,
        ),
      ),
      darkTheme: FusionAppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.montserratTextTheme(
          FusionAppTheme.darkTheme.textTheme,
        ),
      ),
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.loginRoute,
    );
  }
}
