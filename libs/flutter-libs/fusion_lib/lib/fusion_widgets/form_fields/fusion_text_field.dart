import 'package:flutter/material.dart';

/// A customizable and reusable text field for the Fusion design system.
///
/// The [FusionTextField] provides a consistent style across the app,
/// with support for hint text, password fields, keyboard type, and
/// optional change listeners.
///
/// ### Example usage:
/// ```dart
/// FusionTextField(
///   hintText: 'Enter your name',
///   controller: myController,
///   onChanged: (value) {
///     print('Text changed: $value');
///   },
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
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(hintText: hintText, prefixIcon: prefixIcon, suffixIcon: suffixIcon),
    );
  }
}
