import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A secondary action button for the Fusion design system.
///
/// The [SecondaryButton] is designed for less prominent actions and
/// complements primary buttons in layouts.
///
/// It supports outlined styling, gradient backgrounds, loading indicators,
/// disabled states, and optional prefix/suffix icons.
///
/// This button adapts to the current theme and provides consistent
/// visual feedback across the application.
///
/// ### Features
/// - Outlined button style
/// - Optional gradient background
/// - Loading indicator overlay
/// - Disabled and enabled states
/// - Prefix and suffix icon support
/// - Theme-aware foreground and border colors
/// - Customizable size and border radius
///
/// ### Example usage:
/// ```dart
/// SecondaryButton(
///   label: 'Cancel',
///   onTap: () {
///     // Handle cancel action
///   },
///
///   width: 180,
///   height: 45,
///
///   showPrefixIcon: true,
///   prefixIcon: Icons.close,
///
///   showSuffixIcon: true,
///   suffixIcon: Icons.arrow_forward,
///
///   isActive: true,
///   isLoading: false,
///
///   textStyle: const TextStyle(
///     fontSize: 16,
///     fontWeight: FontWeight.w600,
///   ),
/// )
/// ```
///
/// ### Example: Gradient Button
/// ```dart
/// SecondaryButton(
///   label: 'Continue',
///   onTap: () {},
///
///   gradient: const LinearGradient(
///     colors: [Colors.blue, Colors.purple],
///   ),
///
///   showSuffixIcon: true,
///   suffixIcon: Icons.navigate_next,
/// )
/// ```
///
/// ### Example: Disabled State
/// ```dart
/// SecondaryButton(
///   label: 'Submit',
///   onTap: () {},
///   isActive: false,
/// )
/// ```
///
/// ### Notes
/// - When [isLoading] is true, user interaction is disabled.
/// - The loading indicator appears above the button content.
/// - If a gradient is provided, the background becomes transparent.
/// - Uses Fusion color scheme for consistent theming.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final double horizontalPadding;

  final Gradient? gradient;
  final Color? foregroundColor;
  final Color borderColor;

  final bool isLoading;
  final bool isActive;

  final bool showPrefixIcon;
  final IconData? prefixIcon;

  final bool showSuffixIcon;
  final IconData? suffixIcon;

  final String? accessIdentifier;
  final String? accessLabel;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.height = 55,
    this.width = 350,
    this.borderRadius = 8,
    this.textStyle,
    this.horizontalPadding = 12,
    this.foregroundColor,
    this.borderColor = Colors.transparent,
    this.isLoading = false,
    this.isActive = true,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.accessIdentifier,
    this.accessLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = isActive
        ? (foregroundColor ?? context.colorScheme.elevation5)
        : context.colorScheme.elevation2;

    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return Semantics(
      label: accessLabel,
      identifier: accessIdentifier,

      child: SizedBox(
        width: width,
        height: height,

        child: Stack(
          alignment: Alignment.center,

          children: [
            // ================= Gradient / Background =================
            if (gradient != null)
              Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: radius,
                ),
              ),

            // ================= Button =================
            OutlinedButton(
              onPressed: isActive && !isLoading ? onTap : null,

              style: OutlinedButton.styleFrom(
                minimumSize: Size(width, height),

                foregroundColor: effectiveColor,

                side: BorderSide(
                  color: context.colorScheme.elevation5,
                  width: 1,
                ),

                backgroundColor: gradient == null
                    ? (isActive
                          ? Colors.transparent
                          : context.colorScheme.elevation2)
                    : Colors.transparent,

                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  // Prefix
                  if (showPrefixIcon && prefixIcon != null) ...[
                    Icon(
                      prefixIcon,
                      size: 16,
                      color: context.colorScheme.white,
                    ),
                  ],

                  // Label
                  Flexible(
                    child: Center(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,

                        style:
                            textStyle ??
                            TextStyle(
                              fontSize: 14,
                              color: context.colorScheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),

                  // Suffix
                  if (showSuffixIcon && suffixIcon != null) ...[
                    Icon(
                      suffixIcon,
                      size: 16,
                      color: context.colorScheme.white,
                    ),
                  ],
                ],
              ),
            ),

            // ================= Loader =================
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,

                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
