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
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final bool autovalidateMode;
  final InputDecoration? decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final int elevation;
  final TextStyle? style;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final double? itemHeight;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const FusionDropdownButtonFormField({
    super.key,
    required this.options,
    this.value,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.validator,
    this.onSaved,
    this.autovalidateMode = false,
    this.decoration,
    this.hint,
    this.disabledHint,
    this.elevation = 8,
    this.style,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = true, // Default to true to prevent overflow
    this.itemHeight = kMinInteractiveDimension,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: key,
      value: value,
      isExpanded: isExpanded, // Use the parameter value
      items: options
          .map(
            (String option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis, // Handle text overflow
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode ? AutovalidateMode.always : AutovalidateMode.disabled,
      decoration:
          decoration ??
          InputDecoration(
            labelText: hintText ?? 'Select an option',
            contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          ),
      hint: hint,
      disabledHint: disabledHint,
      elevation: elevation,
      style: style,
      icon: icon,
      iconDisabledColor: iconDisabledColor,
      iconEnabledColor: iconEnabledColor,
      iconSize: iconSize,
      isDense: isDense,
      itemHeight: itemHeight,
      focusColor: focusColor,
      focusNode: focusNode,
      autofocus: autofocus,
      dropdownColor: dropdownColor,
      menuMaxHeight: menuMaxHeight,
      enableFeedback: enableFeedback,
      alignment: alignment,
      borderRadius: borderRadius,
    );
  }
}
