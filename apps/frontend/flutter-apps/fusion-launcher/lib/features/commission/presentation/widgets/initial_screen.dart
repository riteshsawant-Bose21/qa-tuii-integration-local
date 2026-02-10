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
              assetColor: context.colorScheme.primaryWhite,
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
                  const SizedBox(height: 16),
                  FusionAppText(
                    text: 'Allow your project to sync with actual hardware installations\nto monitor and control the complete audio system',
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 32),

                  // 3. The "Start" Button
                  FusionNeumorphicButton(
                    onTap: onConfigureNetwork,
                    text: "Configure Network",
                    width: 200,
                    height: 35,
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
