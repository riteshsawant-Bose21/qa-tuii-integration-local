import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context, status);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent, // no background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color, // same as text color
              width: 1,
            ),
          ),
          child: FusionAppText(
            text: _capitalize(status),
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// 🎨 Status Color Logic
  Color _getColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case "healthy":
        return context.colorScheme.successText;

      case "critical":
        return context.colorScheme.volumeRed;

      case "inactive":
        return context.colorScheme.elevation6;

      default:
        return context.colorScheme.elevation6;
    }
  }

  /// 🔤 Capitalize First Letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}