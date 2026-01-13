import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fusion Web',
      debugShowCheckedModeBanner: false,
      theme: FusionAppTheme.lightTheme,
      darkTheme: FusionAppTheme.darkTheme,
      themeMode: ThemeMode.light,

      home: const DashboardPage(),
    );
  }
}
