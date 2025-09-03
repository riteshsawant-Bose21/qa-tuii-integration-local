import 'package:flutter/material.dart';

/// A customizable and reusable text field for the Fusion design system.
///
/// Supports hint text, password fields, keyboard type, custom styles,
/// and consistent theming across the app.
///
/// Example:
/// ```dart
/// FusionTextField(
///   hintText: 'Search',
///   prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
///   suffixIcon: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
///       SizedBox(width: 8),
///       Icon(Icons.sort, size: 20, color: Colors.grey[600]),
///       SizedBox(width: 12),
///     ],
///   ),
/// )
/// ```
class FusionTextField extends StatelessWidget {
  /// Placeholder text displayed inside the field when empty.
  final String hintText;

  /// Controller to manage the text being edited.
  final TextEditingController? controller;

  /// Whether the text field should obscure the text (for passwords).
  final bool obscureText;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// Callback for when the text changes.
  final ValueChanged<String>? onChanged;

  /// Whether the field is enabled or read-only.
  final bool enabled;

  /// Optional prefix icon widget.
  final Widget? prefixIcon;

  /// Optional suffix icon widget.
  final Widget? suffixIcon;

  /// Optional text style for the input text.
  final TextStyle? style;

  /// Optional style for the hint text.
  final TextStyle? hintStyle;

  /// Custom decoration override (if provided, it replaces defaults).
  final InputDecoration? decoration;

  /// Aligns the text inside the field.
  final TextAlign textAlign;

  /// Border for the text field (default: transparent).
  final InputBorder? border;

  const FusionTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
    this.hintStyle,
    this.decoration,
    this.textAlign = TextAlign.start,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultDecoration = InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle ?? theme.inputDecorationTheme.hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: border ?? const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      enabledBorder: border ?? const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: border ?? const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      style: style ?? theme.textTheme.bodySmall,
      textAlign: textAlign,
      decoration: decoration ?? defaultDecoration,
    );
  }
}
