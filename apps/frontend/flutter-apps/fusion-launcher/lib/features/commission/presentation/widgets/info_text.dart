import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class InfoText extends StatelessWidget {
  final String text;

  const InfoText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.info_outline,
          size: 16,
          color: context.colorScheme.iconDefault,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: context.colorScheme.textBody,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
