import 'package:flutter/material.dart';

class WidgetTestScreen extends StatelessWidget {
  const WidgetTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // child: FusionEventCard(
        //   label: "System Shutdown",
        //   description: "Conference on Global Heat Wave",
        //   time: "TODAY / 24 JULY, 2025 / 5:00PM",
        //   color: Colors.green,
        //   width: 400,
        //   height: 180,
        //   onEdit: () {
        //     debugPrint("Edit clicked");
        //   },
        //   onRunNow: () {
        //     debugPrint("Run Now clicked");
        //   },
        //   onCancel: () {
        //     debugPrint("Cancel clicked");
        //   },
        // ),
        // child: MediaPlayerCard(
        //   label: "Beast Mode",
        //   currentstate: true,
        //   width: 300,
        //   height: 70,
        //   onEdit: () {
        //     debugPrint("Edit clicked");
        //   },
        // ),
        // child: FusionPrimaryButton(
        //   text: "Hello",
        //   ontap: () {
        //     debugPrint("Clicked");
        //   },
        //   enabled: true,
        //   width: 300,
        //   height: 50,
        // ),
      ),
    );
  }
}
