import 'package:flutter/material.dart';

class SettingsTabContent extends StatelessWidget {
  const SettingsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Text(
          'Settings Page Content',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
