import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class VipSuccessScreen extends StatelessWidget {
  final VoidCallback onFinish;

  const VipSuccessScreen({
    super.key,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.successFill,
              border: Border.all(
                color: context.colorScheme.successStroke,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 48,
              weight: 0.5,
              color: context.colorScheme.successText,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Network configuration successful',
            style: TextStyle(
              color: context.colorScheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Next Steps >>',
            style: TextStyle(
              color: context.colorScheme.textBody,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Map project devices to physical devices',
            style: TextStyle(
              color: context.colorScheme.textBody,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          FusionNeumorphicButton(
            text: 'Finish',
            onTap: onFinish,
            width: 0.25 * MediaQuery.of(context).size.width,
            height: 35,
          ),
        ],
      ),
    );
  }
}
