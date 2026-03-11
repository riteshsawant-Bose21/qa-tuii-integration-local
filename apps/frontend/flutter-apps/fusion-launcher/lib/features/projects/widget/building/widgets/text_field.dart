import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BuildingPageTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Color? fillColor;

  const BuildingPageTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: context.colorScheme.elevation1,
            ),
            child: PropertyTextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: hintText,
              fillColor: fillColor ?? context.colorScheme.elevation2,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              inputFormatters: inputFormatters,
              validator: validator,
              onChanged: onChanged,
              onSubmitted: onFieldSubmitted,
            ),
          ),
        ),
      ],
    );
  }
}
