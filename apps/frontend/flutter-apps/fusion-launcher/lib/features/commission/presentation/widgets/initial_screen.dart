import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/constants/assets_constants.dart';

class InitialScreen extends StatelessWidget {
  final VoidCallback onConfigureNetwork;

  const InitialScreen({
    super.key,
    required this.onConfigureNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 1. The Illustration
            // Replace with Image.asset('assets/illustration.png') in a real project
            FusionImage.asset(
              Assets.mobileHotspot,
              height: 200,
              assetColor: context.colorScheme.textSecondary,
            ),

            const SizedBox(width: 40),

            // 2. The Text Content
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: 'Configure your devices to\nconnect to the network',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  FusionAppText(
                    text: 'Allow your project to sync with actual hardware installations\nto monitor and control the complete audio system',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. The "Start" Button
                  FusionNeumorphicButton(
                    semanticId: 'configure_network_button',
                    onTap: onConfigureNetwork,
                    text: "Configure Network",
                    width: 358,
                    height: 48,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
