import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A lightweight outlined secondary button for the Fusion design system.
///
/// The [FusionSecondaryButton] is designed for secondary actions
/// that require less visual emphasis than primary buttons.
///
/// It uses an outlined style with theme-based colors and
/// consistent spacing to match Fusion UI guidelines.
///
/// ### Features
/// - Outlined button style
/// - Theme-aware stroke and text colors
/// - Customizable width and height
/// - Rounded corners
/// - Supports disabled state via null [onPressed]
/// - Consistent padding and typography
///
/// ### Example usage:
/// ```dart
/// FusionSecondaryButton(
///   text: 'Cancel',
///   onPressed: () {
///     // Handle cancel action
///   },
///
///   width: 160,
///   height: 40,
/// )
/// ```
///
/// ### Example: Full-width Button
/// ```dart
/// FusionSecondaryButton(
///   text: 'Back',
///   onPressed: () {},
///   width: double.infinity,
/// )
/// ```
///
/// ### Example: Disabled State
/// ```dart
/// FusionSecondaryButton(
///   text: 'Submit',
///   onPressed: null, // Disabled
/// )
/// ```
///
/// ### Notes
/// - When [onPressed] is null, the button becomes disabled.
/// - Colors are derived from [context.colorScheme].
/// - Intended for secondary or low-priority actions.
/// - Uses Material's [OutlinedButton] for accessibility support.

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
