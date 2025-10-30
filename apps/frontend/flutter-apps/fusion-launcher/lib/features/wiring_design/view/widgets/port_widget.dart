import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class PortWidget extends StatelessWidget {
  const PortWidget({super.key, required this.port});
  final CircuitPort port;

  @override
  Widget build(BuildContext context) {
    final String? image2 = port.data.image;
    if (image2 != null) {
      return Image.asset(
        image2,
        fit: BoxFit.fitHeight,
        width: 20,
        height: 20,
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.inactivePortBG,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: Text(
        "${port.data.label}",
        style: context.textTheme.bodySmall?.copyWith(
          fontSize: 8,
        ),
      ),
    );
  }
}
