import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;

  const FusionSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 35,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorScheme.textPrimary,
          side: BorderSide(
            color: context.colorScheme.strokeDark,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
