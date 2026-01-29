import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/navigation/app_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

void main() {
  runApp(const MyApp());
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
