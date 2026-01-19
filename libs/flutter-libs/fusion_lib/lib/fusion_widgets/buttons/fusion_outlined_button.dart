import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../semantics/semantic_helper.dart';
import '../semantics/semantic_type.dart';

/// A customizable and reusable outlined button for the Fusion design system.
///
/// The [FusionOutlinedButton] supports:
/// - Disabled and loading states
/// - Optional prefix and suffix icons
/// - Customizable styling (border, colors, text)
/// - Accessibility labels for screen readers
///
/// ### Example usage:
/// ```dart
/// FusionOutlinedButton(
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
class FusionOutlinedButton extends StatelessWidget {
  /// Text displayed inside the button.
  final String label;

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  /// Height of the button. Default is 55.
  final double height;

  /// Width of the button. Default is 350.
  final double width;

  /// Top margin above the button.
  final double topMargin;

  /// Bottom margin below the button.
  final double bottomMargin;

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

  /// Border color when the button is active. Default is blue.
  final Color? activeBorderColor;

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
  final String? semanticsId;

  /// Semantic label for screen readers.
  final String? accessLabel;

  /// Creates a [FusionOutlinedButton].
  ///
  /// All parameters are optional except [label] and [onTap].
  const FusionOutlinedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 32,
    this.width = 100,
    this.topMargin = 0,
    this.bottomMargin = 0,
    this.borderRadius = 4,
    this.textStyle,
    this.horizontalPadding = 12,
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = Colors.transparent,
    this.activeBorderColor,
    this.isLoading = false,
    this.isActive = true,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.semanticsId,
    this.accessLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, semanticsId ?? label),
      child: Container(
        margin: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
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
                border: Border.all(
                  color: isActive
                      ? activeBorderColor ?? Theme.of(context).colorScheme.primaryBlack
                      : activeBorderColor?.withOpacity(0.5) ?? Theme.of(context).colorScheme.primaryBlack.withOpacity(0.5),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showPrefixIcon && prefixIcon != null) ...[
                          Icon(prefixIcon, size: 16, color: isActive ? foregroundColor : foregroundColor.withOpacity(0.5)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: textStyle ?? Theme.of(context).textTheme.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showSuffixIcon && suffixIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(suffixIcon, size: 16, color: isActive ? foregroundColor : foregroundColor.withOpacity(0.5)),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
