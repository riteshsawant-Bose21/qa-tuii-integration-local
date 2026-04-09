import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../../fusion_lib.dart';

class PropertyTextField extends StatelessWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final String? hintText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final Function(PointerDownEvent event)? onTapOutside;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final TextAlign? textAlign;
  final String? suffixText;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final String? semanticId;

  const PropertyTextField({
    super.key,
    this.initialValue,
    this.controller,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.onTapOutside,
    this.keyboardType,
    this.maxLines,
    this.maxLength,
    this.textAlign,
    this.suffixText,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.validator,
    this.contentPadding,
    this.fillColor,
    this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.formControl(
      testId: SemanticHelper.createTestId(SemanticTypes.textInput, semanticId ?? 'hardware_property_text_field'),
      child: TextFormField(
        autofocus: autofocus,
        focusNode: focusNode,
        initialValue: initialValue,
        controller: controller,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
        textAlign: textAlign ?? TextAlign.start,
        onChanged: onChanged,
        textInputAction: TextInputAction.done,
        onTapOutside: onTapOutside,
        onFieldSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.bodySmall,
        maxLength: maxLength,
        enabled: enabled,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          counterText: '',
          suffixText: suffixText,
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colorScheme.elevation5),
          isDense: true,
          fillColor: fillColor ?? context.colorScheme.elevation1,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: context.colorScheme.strokeLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: context.colorScheme.strokeLight, width: 1),
          ),
        ),
      ),
    );
  }
}
