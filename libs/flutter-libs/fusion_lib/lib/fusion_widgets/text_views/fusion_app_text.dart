import 'package:flutter/material.dart';

/// A customizable text widget for the Fusion design system.
///
/// The [FusionAppText] widget provides a consistent way to display styled text
/// with advanced customization options, accessibility support, and optional
/// currency or underline features.
///
/// It supports:
/// - Custom text color, size, weight, and style
/// - Optional underline with customizable underline color
/// - Optional currency symbol prefix (₹)
/// - Control over wrapping, overflow, and line limits
/// - Accessibility identifiers and labels for screen readers
/// - Full override with a custom [TextStyle]
///
/// ### Example usage:
///
///```dart
///
/// FusionAppText(
///   text: '1,250',
///   isCurrency: true,
///   underLine: true,
///   underlineColor: Colors.greenAccent,
/// ),
///
/// FusionAppText(
///   text: 'Custom Styled',
///   style: TextStyle(
///     fontSize: 20,
///     color: Colors.blue,
///     fontWeight: FontWeight.bold,
///   ),
/// ),
///

class FusionAppText extends StatelessWidget {
  /// The text to display.
  final String text;

  /// The font weight of the text.
  final FontWeight fontWeight;

  /// The font style of the text.
  final FontStyle fontStyle;

  /// The line height of the text.
  final double lineHeight;

  /// The alignment of the text.
  final TextAlign textAlign;

  /// The maximum number of lines for the text.
  final int? maxLine;

  /// Whether the text should wrap if it exceeds the width.
  final bool softWrap;

  /// Whether the text should be underlined.
  final bool underLine;

  /// The overflow behavior for the text.
  final TextOverflow? textOverflow;

  /// Accessibility identifier for the text.
  final String? accessIdentifier;

  /// Accessibility label for the text.
  final String? accessLabel;

  /// Custom text style to override default styling.
  final TextStyle? style;

  /// Creates a [FusionAppText] widget.
  ///
  /// [text] is required and specifies the string to display.
  /// [textColor] and [fontSize] are required for styling.
  /// Other parameters are optional and provide further customization.
  const FusionAppText({
    super.key,
    required this.text,
    this.style,
    this.fontWeight = FontWeight.w600,
    this.textAlign = TextAlign.start,
    this.softWrap = true,
    this.lineHeight = 1.0,
    this.maxLine,
    this.fontStyle = FontStyle.normal,
    this.underLine = false,
    this.accessIdentifier,
    this.accessLabel,
    this.textOverflow,
  });

  @override
  Widget build(BuildContext context) {
    /// Builds the FusionAppText widget with semantics for accessibility.
    return Semantics(
      container: true,
      identifier: accessIdentifier ?? text,
      label: accessLabel ?? text,

      /// Exclude semantics from the child widget to avoid redundancy.
      child: ExcludeSemantics(
        excluding: true,

        /// Displays the text with the specified properties.
        child: Text(
          text,
          textAlign: textAlign,
          overflow: textOverflow ?? ((maxLine != null) ? TextOverflow.ellipsis : null),
          maxLines: maxLine,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
          softWrap: softWrap,
        ),
      ),
    );
  }
}
