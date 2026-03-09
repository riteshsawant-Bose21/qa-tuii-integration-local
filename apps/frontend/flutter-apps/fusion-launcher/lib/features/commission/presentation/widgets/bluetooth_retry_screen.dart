import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/assets/asset_images.dart';
import 'info_text.dart';

class BluetoothRetryScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const BluetoothRetryScreen({
    super.key,
    required this.onRetry,
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
            'Oh no! We could not find any Bluetooth\ndevices',
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
            text: 'Make sure your Bluetooth devices are turned on',
          ),
          const SizedBox(height: 24),
          FusionNeumorphicButton(
            height: 35,
            text: 'Retry connection',
            onTap: onRetry,
            width: 0.25 * MediaQuery.of(context).size.width,
          ),
        ],
      ),
    );
  }
}
