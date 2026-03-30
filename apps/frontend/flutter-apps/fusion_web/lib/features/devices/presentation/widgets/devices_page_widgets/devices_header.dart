import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class DevicesHeader extends StatelessWidget {
  const DevicesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FusionAppText(
          text: 'Devices',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLine: 2,
        ),
        const SizedBox(height: 4),
        FusionAppText(
          text: 'Monitor and manage all devices across your ecosystem',
        ),
      ],
    );
  }
}
