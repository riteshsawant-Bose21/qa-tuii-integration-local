import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String assetPath;

  const DeviceInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.elevation2, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionImage.asset(
            assetPath,
            height: 16,
            width: 16,
            assetColor: context.colorScheme.textSecondary,
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: label,
            style: context.textTheme.labelSmall!.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FusionAppText(
            text: value,
            style: context.textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
