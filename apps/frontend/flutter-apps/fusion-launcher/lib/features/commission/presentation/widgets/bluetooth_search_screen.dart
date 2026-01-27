import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/buttons/secondary_button.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'info_text.dart';
import 'loading_indicator.dart';

class BluetoothSearchScreen extends StatelessWidget {
  final VoidCallback onGoBack;

  const BluetoothSearchScreen({
    super.key,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Hold on, searching for Bluetooth devices',
              style: TextStyle(
                color: context.colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          const LoadingIndicator(
            icon: Icons.bluetooth,
          ),
          const Spacer(),
          const InfoText(
            text: 'Make sure you Bluetooth devices aew turned on',
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            text: 'Go back',
            onPressed: onGoBack,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
