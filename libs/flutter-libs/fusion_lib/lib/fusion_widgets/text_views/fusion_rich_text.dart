import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// A customizable rich text widget for the Fusion design system.
///
/// The [FusionRichText] widget allows you to display text with multiple styles
/// and inline formatting while supporting underline, gradient fills, and
/// accessibility semantics.
///
/// It supports:
/// - Applying different styles to portions of text via [inlineSpans]
/// - Optional gradient fill for the main text
/// - Currency symbol (₹) prefix
/// - Optional underline with custom color
/// - Wrapping, overflow control, and max line limits
/// - Accessibility identifiers and labels for screen readers
///
/// ### Example usage:
/// ```dart
/// // 1. Simple styled text
/// FusionRichText(
///   text: 'Hello Fusion',
///   textStyle: TextStyle(fontSize: 20, color: Colors.black),
/// )
///
/// // 2. Text with currency symbol and underline
/// FusionRichText(
///   text: '1,250',
///   textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
///   isCurrency: true,
///   underLine: true,
///   underlineColor: Colors.red,
/// )
///
/// // 3. Gradient text
/// FusionRichText(
///   text: 'Gradient Title',
///   textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
///   gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
/// )
///
/// // 4. Rich text with inline spans
/// FusionRichText(
///   text: 'Hello ',
///   textStyle: TextStyle(fontSize: 18, color: Colors.black),
///   inlineSpans: [
///     TextSpan(
///       text: 'Fusion',
///       style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
///     ),
///     TextSpan(
///       text: ' World!',
///       style: TextStyle(color: Colors.green),
///     ),
///   ],
/// )
/// ```
class FusionRichText extends StatelessWidget {
  /// The main text content to display.
  final String text;

  /// The style to apply to the main text.
  final TextStyle textStyle;

  /// Optional gradient for the main text.
  final Gradient? gradient;

  /// Whether to prefix the text with a currency symbol (₹).
  final bool isCurrency;

  /// Whether to underline the text.
  final bool underLine;

  /// Color for the underline if enabled.
  final Color? underlineColor;

  /// Text alignment for the rich text.
  final TextAlign textAlign;

  /// Maximum number of lines to display.
  final int? maxLine;

  /// Whether the text should wrap to the next line.
  final bool softWrap;

  /// Overflow behavior for the text.
  final TextOverflow? textOverflow;

  /// Accessibility identifier for the text.
  final String? accessIdentifier;

  /// Accessibility label for screen readers.
  final String? accessLabel;

  /// List of additional inline spans for styling specific parts of the text.
  final List<InlineSpan>? inlineSpans;

  /// Creates a [FusionRichText] widget.
  ///
  /// [text] and [textStyle] are required.
  const FusionRichText({
    super.key,
    required this.text,
    required this.textStyle,
    this.gradient,
    this.isCurrency = false,
    this.underLine = false,
    this.underlineColor,
    this.textAlign = TextAlign.start,
    this.maxLine,
    this.softWrap = true,
    this.textOverflow,
    this.accessIdentifier,
    this.accessLabel,
    this.inlineSpans,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = textStyle.copyWith(
      decoration: underLine ? TextDecoration.underline : TextDecoration.none,
      decorationColor: underLine ? underlineColor ?? Theme.of(context).colorScheme.textPrimary : null,
      foreground: gradient != null ? (Paint()..shader = gradient!.createShader(const Rect.fromLTWH(0, 0, 200, 70))) : null,
    );

    return Semantics(
      container: true,
      identifier: accessIdentifier ?? text,
      label: accessLabel ?? text,
      child: ExcludeSemantics(
        excluding: true,
        child: RichText(
          textAlign: textAlign,
          maxLines: maxLine,
          softWrap: softWrap,
          overflow: textOverflow ?? ((maxLine != null) ? TextOverflow.ellipsis : TextOverflow.clip),
          text: TextSpan(text: isCurrency ? '\u{20B9}$text' : text, style: baseStyle, children: inlineSpans),
        ),
      ),
    );
  }
}
