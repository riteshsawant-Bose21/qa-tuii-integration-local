import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/wiring_design/model/circuit_port.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class PortConnectionOverlay extends StatefulWidget {
  const PortConnectionOverlay({super.key, required this.port});
  final CircuitPort port;
  @override
  State<PortConnectionOverlay> createState() => _PortConnectionOverlayState();
}

class _PortConnectionOverlayState extends State<PortConnectionOverlay> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.borderColorL,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Connect Port ${widget.port.data.label} to ",
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.portOverlayTitle,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
