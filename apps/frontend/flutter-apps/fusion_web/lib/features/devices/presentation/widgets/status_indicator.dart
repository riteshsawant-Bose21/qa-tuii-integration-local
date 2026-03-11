import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBgColor(status);
    final textColor = _getTextColor(status);

    return Row(
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _capitalize(status),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }


  Color _getBgColor(String status) {
    switch (status) {
      case "healthy":
        return Colors.green.shade100;
      case "critical":
        return Colors.red.shade100;
      case "inactive":
        return Colors.grey.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case "healthy":
        return Colors.green.shade700;
      case "critical":
        return Colors.red.shade700;
      case "inactive":
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _capitalize(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
