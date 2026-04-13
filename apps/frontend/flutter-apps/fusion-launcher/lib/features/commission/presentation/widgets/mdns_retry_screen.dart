import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/assets/asset_images.dart';
import 'info_text.dart';

class MDNSRetryScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onConfigureWireless;

  const MDNSRetryScreen({
    super.key,
    required this.onRetry,
    required this.onConfigureWireless,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FusionImage.asset(
            AssetImages.notFound,
            height: 150,
            assetColor: context.colorScheme.iconWhite,
          ),
          const SizedBox(height: 32),
          Text(
            'Oh no! We could not detect any Fusion\nnetwork',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const InfoText(
            text: 'Make sure you are connected to right network',
          ),
          const SizedBox(height: 24),
          FusionNeumorphicButton(
            semanticId: 'retry_connection_button',
            text: 'Retry',
            onTap: onRetry,
            width: 0.25 * MediaQuery.of(context).size.width,
            height: 35,
          ),
          const SizedBox(height: 16),
          // Text(
          //   '-or-',
          //   style: TextStyle(
          //     color: context.colorScheme.textBody,
          //     fontSize: 14,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // Text(
          //   'Do you have other wireless devices to configure?',
          //   style: TextStyle(
          //     color: context.colorScheme.textBody,
          //     fontSize: 14,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // FusionSecondaryButton(
          //   semanticId: 'mdns_configure_wireless_button',
          //   text: 'Configure Wireless Devices',
          //   onPressed: onConfigureWireless,
          //   width: 0.25 * MediaQuery.of(context).size.width,
          // ),
        ],
      ),
    );
  }
}
