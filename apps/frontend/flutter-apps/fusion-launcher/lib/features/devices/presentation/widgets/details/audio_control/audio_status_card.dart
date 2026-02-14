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
        color: const Color(0xFF1E1E1E), // Dark card background
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24), // Increased padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: title.toUpperCase(),
            style: context.textTheme.labelSmall!.copyWith(
              color: const Color(0xFF9E9E9E), // Grey header text
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF333333)), // Subtle divider
          const SizedBox(height: 16),
          Expanded(child: content),
        ],
      ),
    );
  }
}
