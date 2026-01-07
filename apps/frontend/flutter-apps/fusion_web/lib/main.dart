import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

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
      themeMode: ThemeMode.dark,
    );
  }
}
