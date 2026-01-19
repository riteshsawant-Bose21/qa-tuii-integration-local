import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/constants/assets_constants.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigureDevicePage extends StatelessWidget {
  final VoidCallback onStartPressed;
  const ConfigureDevicePage({super.key, required this.onStartPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 1. The Illustration
              // Replace with Image.asset('assets/illustration.png') in a real project
              Image.asset(
                Assets.mobileHotspot,
                height: 200,
                color: context.colorScheme.primaryBlack,
              ),

              const SizedBox(width: 40),

              // 2. The Text Content
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Configure your devices to\nconnect to the network',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primaryBlack,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Allow your project to sync with actual hardware installations\nto monitor and control the complete audio system',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colorScheme.greyLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. The "Start" Button
                    ElevatedButton(
                      onPressed: onStartPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: context.colorScheme.primaryBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const FusionAppText(
                        text: 'Start',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
