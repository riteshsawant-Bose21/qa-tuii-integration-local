import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

/// A customizable and reusable text field for the Fusion design system.
///
/// The [FusionTextFormField] supports:
/// - Title and hint text
/// - Required field indicator
/// - Multiple input restrictions (number only, no spaces, etc.)
/// - Password toggle visibility
/// - Error state styling
/// - Read-only and active/inactive states
/// - Full styling control
///
/// ### Example usage:
/// ```dart
/// FusionTextField(
///   title: 'Email',
///   hintText: 'Enter your email',
///   isRequired: true,
///   onChanged: (value) => print(value),
/// )
///
/// FusionTextField(
///   title: 'Password',
///   hintText: 'Enter password',
///   isPassword: true,
///   onChanged: (value) => print(value),
/// )
/// ```
class FusionTextFormField extends StatefulWidget {
  /// Title text displayed above the field.
  final String title;

  /// Placeholder text inside the field.
  final String hintText;

  /// Whether the field is required (adds a red asterisk).
  final bool isRequired;

  /// Whether the field is a password field (hides text).
  final bool isPassword;

  /// Whether the field starts with text hidden (for password fields).
  final bool isPasswordHidden;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field is active (affects styling).
  final bool isActive;

  /// Whether to show error styling.
  final bool hasError;

  /// Number of text lines. Defaults to `1`.
  final int maxLines;

  /// Maximum character length. Defaults to `60`.
  final int maxLength;

  /// Input type restrictions.
  final TextInputType keyboardType;

  /// Text input action.
  final TextInputAction inputAction;

  /// Prefix text displayed before input.
  final String? prefixText;

  /// Prefix text style.
  final TextStyle? prefixTextStyle;

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Validator function.
  final FormFieldValidator<String>? validator;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// Submit callback.
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final String semanticId;

  /// Creates a [FusionTextFormField].
  const FusionTextFormField({
    super.key,
    required this.title,
    required this.semanticId,
    required this.hintText,
    this.isRequired = false,
    this.isPassword = false,
    this.isPasswordHidden = false,
    this.readOnly = false,
    this.isActive = true,
    this.hasError = false,
    this.maxLines = 1,
    this.maxLength = 60,
    this.keyboardType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.prefixText,
    this.prefixTextStyle,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<FusionTextFormField> createState() => _FusionTextFormFieldState();
}

class _FusionTextFormFieldState extends State<FusionTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPasswordHidden;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title
        if (widget.title.isNotEmpty)
          Row(
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.labelMedium),
              if (widget.isRequired) Text(' *', style: TextStyle(color: Colors.red.shade600)),
            ],
          ),
        if (widget.title.isNotEmpty) const SizedBox(height: 8),

        /// Text Field
        FusionContainer(
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            textInputAction: widget.inputAction,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            obscureText: widget.isPassword ? _obscureText : false,
            // style: TextStyle(color: widget.isActive ? Colors.black : Colors.black.withOpacity(0.4)),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixText: widget.prefixText,
              prefixStyle: widget.prefixTextStyle,
              prefixIcon: widget.prefixIcon,

              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counter: SizedBox(),
              filled: false,
              suffixIcon:
                  widget.suffixIcon ??
                  (widget.isPassword
                      ? IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey.shade600),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : null),
            ),
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
      ],
    );
  }
}
