import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeAuthToken();

  runApp(const MyApp());
}

Future<void> _initializeAuthToken() async {
  try {
    final dataSource = Auth0DataSource();
    final repository = AuthRepositoryImpl(dataSource: dataSource);

    final isLoggedIn = await repository.isLoggedIn();
    if (isLoggedIn) {
      final token = await repository.getIdToken();
      if (token != null) {
        ServiceLocator().apiService.setBearerToken(token);
      }
    }
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: appRouter,
    );
  }
}