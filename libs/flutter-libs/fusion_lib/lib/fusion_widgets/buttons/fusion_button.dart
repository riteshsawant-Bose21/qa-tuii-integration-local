import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// A customizable and reusable button for the Fusion design system.
///
/// The [FusionButton] supports disabled states, loading indicators,
/// optional prefix/suffix icons, and full styling control.
///
/// ### Example usage:
/// ```dart
/// FusionButton(
///   label: 'Proceed',
///   onTap: () {
///     // Your action
///   },
///   showPrefixIcon: true,
///   prefixIcon: Icons.arrow_back,
///   showSuffixIcon: true,
///   suffixIcon: Icons.check,
///   isActive: true,
///   isLoading: false,
///   textStyle: const TextStyle(
///     fontSize: 18,
///     fontWeight: FontWeight.bold,
///     color: Colors.white,
///   ),
/// )
/// ```
class FusionButton extends StatelessWidget {
  /// Text displayed inside the button.
  final String label;

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  /// Height of the button. Default is 55.
  final double height;

  /// Width of the button. Default is 350.
  final double width;

  /// Border radius for rounded corners.
  final double borderRadius;

  /// Text style for the button label.
  final TextStyle? textStyle;

  /// Horizontal padding inside the button.
  final double horizontalPadding;

  /// Background color when the button is active.
  final Color? activeBackgroundColor;

  /// Text/icon color.
  final Color? foregroundColor;

  /// Color of the button border.
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

  /// Gradient to use when the button is active.
  final Gradient? gradient;

  /// Creates a [FusionButton].
  ///
  /// All parameters are optional except [label] and [onTap].
  const FusionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.height = 55,
    this.width = 350,
    this.borderRadius = 8,
    this.textStyle,
    this.horizontalPadding = 12,
    this.activeBackgroundColor,
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
                gradient: isActive ? gradient : gradient?.withOpacity(0.3),
                color: isActive
                    ? (activeBackgroundColor ?? Theme.of(context).colorScheme.fusionButtonColor)
                    : (activeBackgroundColor?.withValues(alpha: 0.3) ?? Theme.of(context).colorScheme.fusionButtonColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isActive || borderColor == Colors.transparent ? borderColor : borderColor.withValues(alpha: 0.4),
                  width: borderColor == Colors.transparent ? 0 : 1.5,
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.fusionButtonTextColor,
                        ),
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
                                ? foregroundColor ?? Theme.of(context).colorScheme.fusionButtonTextColor
                                : foregroundColor?.withValues(alpha: 0.5) ?? Theme.of(context).colorScheme.fusionButtonTextColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: (textStyle ?? Theme.of(context).textTheme.labelLarge)?.copyWith(
                              color: isActive
                                  ? foregroundColor ?? Theme.of(context).colorScheme.fusionButtonTextColor
                                  : foregroundColor?.withValues(alpha: 0.5) ?? Theme.of(context).colorScheme.fusionButtonTextColor.withValues(alpha: 0.5),
                            ),
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
                                : foregroundColor?.withValues(alpha: 0.5) ?? Theme.of(context).colorScheme.fusionButtonTextColor.withValues(alpha: 0.5),
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
