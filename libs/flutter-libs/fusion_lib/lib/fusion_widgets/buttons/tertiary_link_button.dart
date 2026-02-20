import 'package:flutter/material.dart';

import '../semantics/semantic_helper.dart';
import '../semantics/semantic_type.dart';

/// A customizable and reusable text button for the Fusion design system.
///
/// The [TertiaryLinkButton] supports:
/// - Disabled and loading states
/// - Optional prefix and suffix icons
/// - Customizable styling (colors, text)
/// - Accessibility labels for screen readers
///
/// ### Example usage:
/// ```dart
/// TertiaryLinkButton(
///   label: 'Cancel',
///   onTap: () {
///     // Your action
///   },
///   showPrefixIcon: true,
///   prefixIcon: Icons.close,
///   showSuffixIcon: true,
///   suffixIcon: Icons.arrow_forward,
///   isActive: true,
///   isLoading: false,
///   textStyle: TextStyle(
///     fontSize: 16,
///     fontWeight: FontWeight.w600,
///     color: Colors.black,
///   ),
/// )
/// ```
class TertiaryLinkButton extends StatelessWidget {
  /// Text displayed inside the button.
  final String label;

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  /// Height of the button. Default is 55.
  final double height;

  /// Width of the button. Default is 350.
  final double width;

  /// Border radius for rounded corners. Default is 8.
  final double borderRadius;

  /// Text style for the button label.
  final TextStyle? textStyle;

  /// Horizontal padding inside the button.
  final double horizontalPadding;

  /// Color of the text and icons.
  final Color foregroundColor;

  /// Background color of the button. Default is transparent.
  final Color backgroundColor;

  /// Indicates whether the button is in a loading state.
  final bool isLoading;

  /// Indicates whether the button is active and clickable.
  final bool isActive;

  /// Whether to show a prefix icon.
  final bool showPrefixIcon;

  /// Icon to be shown before the text if [showPrefixIcon] is true.
  final IconData? prefixIcon;

  /// Whether to show a suffix icon.
  final bool showSuffixIcon;

  /// Icon to be shown after the text if [showSuffixIcon] is true.
  final IconData? suffixIcon;

  /// Identifier for testing or accessibility tools.
  final String? accessIdentifier;

  /// Semantic label for screen readers.
  final String? accessLabel;
  final TextAlign textAlign;

  /// Creates a [TertiaryLinkButton].
  ///
  /// All parameters are optional except [label] and [onTap].
  const TertiaryLinkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 55,
    this.width = 350,
    this.textAlign = TextAlign.center,
    this.borderRadius = 8,
    this.textStyle,
    this.horizontalPadding = 12,
    this.foregroundColor = const Color(0xFFFFFFFF),
    this.backgroundColor = Colors.transparent,
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
    return SemanticHelper.button(
      enabled: isActive,
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        accessLabel ?? label,
      ),
      child: IgnorePointer(
        ignoring: isLoading || !isActive,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            width: width,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              // No border - this is the only difference from FusionOutlinedButton
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showPrefixIcon && prefixIcon != null) ...[
                        Icon(
                          prefixIcon,
                          size: 16,
                          color: isActive
                              ? foregroundColor
                              : foregroundColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Center(
                              child: Text(
                                label,
                                textAlign: textAlign,
                                style:
                                    textStyle ??
                                    TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 2,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showSuffixIcon && suffixIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          suffixIcon,
                          size: 16,
                          color: isActive
                              ? foregroundColor
                              : foregroundColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
