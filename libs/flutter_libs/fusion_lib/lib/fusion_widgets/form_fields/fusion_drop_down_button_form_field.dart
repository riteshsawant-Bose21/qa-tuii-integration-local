import 'package:flutter/material.dart';

/// A reusable dropdown form field for Fusion design system.
///
/// Example:
/// ```dart
/// FusionDropdownButtonFormField(
///   options: ['Option 1', 'Option 2', 'Option 3'],
///   onChanged: (value) {
///     print('Selected: $value');
///   },
/// )
/// ```
class FusionDropdownButtonFormField extends StatelessWidget {
  final List<String> options;
  final String? value;
  final String? hintText;
  final ValueChanged<String?>? onChanged;

  const FusionDropdownButtonFormField({super.key, required this.options, this.value, this.hintText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hintText ?? 'Select an option',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: options.map((String option) => DropdownMenuItem<String>(value: option, child: Text(option))).toList(),
      onChanged: onChanged,
    );
  }
}
