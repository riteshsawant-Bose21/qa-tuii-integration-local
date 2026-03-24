import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class AudioStatusCard extends StatelessWidget {
  final String title;
  final Widget content;

  const AudioStatusCard({
    required this.title,
    required this.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24), // Increased padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: title.toUpperCase(),
            style: context.textTheme.labelSmall!.copyWith(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: context.colorScheme.strokeDark,
          ), // Subtle divider
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
