import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class WidgetDetailsSection extends StatelessWidget {
  const WidgetDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: context.colorScheme.elevation2),
      ),
      child: const Center(
        child: FusionAppText(text: 'Widget Details Section'),
      ),
    );
  }
}
