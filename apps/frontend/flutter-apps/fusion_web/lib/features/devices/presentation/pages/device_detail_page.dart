import 'package:flutter/material.dart';

class DeviceDetailPage extends StatelessWidget {
  final String id;

  const DeviceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Device $id"),
      ),
      body: Center(
        child: Text(
          "Device ID: $id",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}