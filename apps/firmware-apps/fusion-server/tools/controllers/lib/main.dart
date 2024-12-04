import 'package:flutter/material.dart';
import 'package:controllers/widgets/controller_selector.dart';

void main() {
  runApp(const ControllerApp(host: '192.168.64.100'));
}

class ControllerApp extends StatelessWidget {
  final String host;

  const ControllerApp({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controllers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ControllerSelector(host: host),
      debugShowCheckedModeBanner: false,
    );
  }
}
