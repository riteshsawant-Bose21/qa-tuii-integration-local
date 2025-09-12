import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// A customizable and reusable gradient button for the Fusion design system.
///
/// The [FusionGradientButton] supports disabled states, loading indicators,
/// optional prefix/suffix icons, full styling control, and semantic accessibility.
///
/// It uses a linear gradient background when active and falls back to a
/// grey color when inactive.
///
/// ### Example usage:
/// ```dart
/// FusionGradientButton(
///   label: 'Continue',
///   onTap: () {
///     // Your action
///   },
///   gradient: LinearGradient(
///     colors: [Colors.blue, Colors.purple],
///     begin: Alignment.topLeft,
///     end: Alignment.bottomRight,
///   ),
///   isLoading: false,
///   isActive: true,
///   showPrefixIcon: true,
///   prefixIcon: Icons.arrow_forward,
/// )
/// ```
class FusionGradientButton extends StatelessWidget {
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

  /// Horizontal padding inside the button. Default is 12.
  final double horizontalPadding;

  /// Gradient to use when the button is active.
  final Gradient gradient;

  /// Text and icon color. Default is white.
  final Color? foregroundColor;

  /// Color of the button border. Default is transparent.
  final Color borderColor;

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

  /// Creates a [FusionGradientButton].
  ///
  /// The [label], [onTap], and [gradient] parameters are required.
  const FusionGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.gradient,
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
    final Color effectiveBorderColor = isActive || borderColor == Colors.transparent ? borderColor : borderColor.withOpacity(0.4);

    return Semantics(
      button: true,
      label: accessLabel ?? label,
      identifier: accessIdentifier ?? label,
      enabled: isActive,
      child: ExcludeSemantics(
        excluding: true,
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
                gradient: isActive ? gradient : null,
                color: isActive ? null : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: effectiveBorderColor),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
                                ? foregroundColor ?? Theme.of(context).colorScheme.fusionButtonTextColor
                                : foregroundColor?.withOpacity(0.5) ?? Theme.of(context).colorScheme.fusionButtonTextColor.withOpacity(0.5),
                          ),
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
                          Icon(
                            suffixIcon,
                            size: 16,
                            color: isActive
                                ? foregroundColor ?? Theme.of(context).colorScheme.fusionButtonTextColor
                                : foregroundColor?.withOpacity(0.5) ?? Theme.of(context).colorScheme.fusionButtonTextColor.withOpacity(0.5),
                          ),
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
