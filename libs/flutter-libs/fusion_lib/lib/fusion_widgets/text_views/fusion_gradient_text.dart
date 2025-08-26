import 'package:flutter/material.dart';

/// A customizable gradient text widget for the Fusion design system.
///
/// The [FusionGradientText] widget displays text with a gradient fill
/// and supports underline, currency prefix, wrapping, and accessibility.
///
/// ### Features:
/// - Adaptive gradient sizing (fits text width dynamically)
/// - Supports all gradient types (linear, radial, sweep)
/// - Optional underline with custom color
/// - Currency symbol (₹) prefix option
/// - Max lines, overflow handling, and text wrapping
/// - Accessibility identifiers and labels
///
/// ### Example usage:
/// ```dart
/// FusionGradientText(
///   text: 'Fusion Gradient',
///   gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
///   fontSize: 28,
///   fontWeight: FontWeight.bold,
/// )
///
/// FusionGradientText(
///   text: '1,250',
///   gradient: LinearGradient(colors: [Colors.orange, Colors.red]),
///   fontSize: 20,
///   isCurrency: true,
///   underLine: true,
///   underlineColor: Colors.redAccent,
/// )
/// ```
class FusionGradientText extends StatelessWidget {
  final String text;
  final Gradient? gradient;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final double lineHeight;
  final TextAlign textAlign;
  final int? maxLine;
  final bool softWrap;
  final bool underLine;
  final Color? underlineColor;
  final bool isCurrency;
  final TextOverflow? textOverflow;
  final String? accessIdentifier;
  final String? accessLabel;
  final TextStyle? style;

  const FusionGradientText({
    super.key,
    required this.text,
    this.gradient,
    required this.fontSize,
    this.style,
    this.fontWeight = FontWeight.w600,
    this.fontStyle = FontStyle.normal,
    this.lineHeight = 1.0,
    this.textAlign = TextAlign.start,
    this.maxLine,
    this.softWrap = true,
    this.underLine = false,
    this.underlineColor,
    this.isCurrency = false,
    this.accessIdentifier,
    this.accessLabel,
    this.textOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = isCurrency ? '\u{20B9}$text' : text;
    final colorScheme = Theme.of(context).colorScheme;

    // Use provided gradient or default theme-aware gradient
    final effectiveGradient = gradient ?? _getDefaultGradient(colorScheme);

    return Semantics(
      container: true,
      identifier: accessIdentifier ?? text,
      label: accessLabel ?? text,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return effectiveGradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
            },
            child: Text(
              displayText,
              textAlign: textAlign,
              overflow: textOverflow ?? ((maxLine != null) ? TextOverflow.ellipsis : null),
              maxLines: maxLine,
              softWrap: softWrap,
              style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                height: lineHeight,
                decoration: underLine ? TextDecoration.underline : TextDecoration.none,
                decorationColor: underlineColor,
                color: Colors.white, // Required for ShaderMask
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns the default gradient based on the current theme
  Gradient _getDefaultGradient(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else {
      return const LinearGradient(colors: [Color(0xFF80DEEA), Color(0xFF4DD0E1)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }
}
