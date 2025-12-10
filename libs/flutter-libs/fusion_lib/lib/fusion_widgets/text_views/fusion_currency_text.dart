import 'package:flutter/material.dart';

/// Supported currency types for [FusionAppText].
enum CurrencyType {
  inr, // Indian Rupee
  usd, // US Dollar
  eur, // Euro
  gbp, // British Pound
  jpy, // Japanese Yen
  cny, // Chinese Yuan
  aud, // Australian Dollar
  cad, // Canadian Dollar
  custom; // For any custom currency symbol

  static CurrencyType? fromString(String value) {
    try {
      return CurrencyType.values.firstWhere((CurrencyType element) => element.name == value);
    } catch (e) {
      return null;
    }
  }
}

/// A customizable text widget for the Fusion design system.
///
/// The [FusionAppText] widget provides a consistent way to display styled text
/// with advanced customization options, accessibility support, and optional
/// currency or underline features.
///
/// It supports:
/// - Custom text color, size, weight, and style
/// - Optional underline with customizable underline color
/// - Optional currency symbol prefix (₹, $, €, etc.)
/// - Control over wrapping, overflow, and line limits
/// - Accessibility identifiers and labels for screen readers
/// - Full override with a custom [TextStyle]
///
/// ### Example usage:
///
///```dart
/// FusionCurrencyText(
///   text: '1,250',
///   isCurrency: true,
///   currencyType: CurrencyType.usd,
/// ),
///
/// FusionCurrencyText(
///   text: '1,250',
///   isCurrency: true,
///   currencyType: CurrencyType.custom,
///   customCurrencySymbol: 'د.إ', // AED
/// ),
///```
class FusionCurrencyText extends StatelessWidget {
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

  /// The currency type to use (default: INR).
  final CurrencyType? currencyType;

  /// If [currencyType] is [CurrencyType.custom], provide this custom symbol.
  final String? customCurrencySymbol;

  /// The overflow behavior for the text.
  final TextOverflow? textOverflow;

  /// Accessibility identifier for the text.
  final String? accessIdentifier;

  /// Accessibility label for the text.
  final String? accessLabel;

  /// Custom text style to override default styling.
  final TextStyle? style;

  /// Creates a [FusionCurrencyText] widget.
  const FusionCurrencyText({
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
    this.currencyType = CurrencyType.usd,
    this.customCurrencySymbol,
    this.accessIdentifier,
    this.accessLabel,
    this.textOverflow,
  });

  /// Returns the correct currency symbol for the given [CurrencyType].
  String _getCurrencySymbol() {
    switch (currencyType) {
      case CurrencyType.usd:
        return '\$';
      case CurrencyType.eur:
        return '€';
      case CurrencyType.gbp:
        return '£';
      case CurrencyType.jpy:
        return '¥';
      case CurrencyType.cny:
        return '¥';
      case CurrencyType.aud:
        return 'A\$';
      case CurrencyType.cad:
        return 'C\$';
      case CurrencyType.custom:
        return customCurrencySymbol ?? '';
      case CurrencyType.inr:
        return '₹';
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: accessIdentifier ?? text,
      label: accessLabel ?? text,
      child: ExcludeSemantics(
        excluding: true,
        child: Text(
          '${_getCurrencySymbol()}$text',
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
