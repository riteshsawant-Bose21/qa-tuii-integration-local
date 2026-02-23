import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/settings/network_settings_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'device_security.dart';

class PasscodeSettingsPage extends StatelessWidget {
  const PasscodeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              const NetworkSettingsHeader(title: "PASSCODE AND SECURITY"),

              // --- Section 1: Device Settings ---
              const SecuritySection(
                sectionTitle: "Device Settings",
                radioLabel: "Security Level", // Added per request
                passcodeLabel: "Setting Passcode",
              ),

              const SizedBox(height: 24),

              // --- Divider (Dashed) ---
              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: DashedLinePainter(
                  color: context.colorScheme.elevation2,
                  dashWidth: 4,
                  dashSpace: 4,
                ),
              ),

              const SizedBox(height: 24),

              // --- Section 2: Control Panel Settings ---
              // Note: sectionTitle is null because the image shows the controls directly
              // under the divider, but you can add "Control Panel" if preferred.
              // Based on image "Security Level" acts as the first row.
              const SecuritySection(
                sectionTitle: "Control Panel Settings",
                radioLabel: "Security Level",
                passcodeLabel: "Control Panel Passcode",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Painter for the dashed divider shown in the image
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
