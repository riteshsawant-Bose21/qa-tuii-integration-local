import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'info_text.dart';
import 'loading_indicator.dart';

class MDNSSearchScreen extends StatelessWidget {
  final VoidCallback onConfigureWireless;

  const MDNSSearchScreen({
    super.key,
    required this.onConfigureWireless,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Hold on, searching for Fusion system',
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        const LoadingIndicator(
          icon: Icons.cell_tower_rounded, // Or auto_awesome for "Fusion" feel
        ),
        const Spacer(),
        const InfoText(
          text: 'Make sure you are connected to right network',
        ),
        const SizedBox(height: 16),
        Text(
          '-or-',
          style: TextStyle(
            color: context.colorScheme.textBody,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Do you have other wireless devices to configure?',
          style: TextStyle(
            color: context.colorScheme.textBody,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        FusionSecondaryButton(
          semanticId: 'mdns_configure_wireless_button',
          text: 'Configure Wireless Devices',
          onPressed: onConfigureWireless,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
