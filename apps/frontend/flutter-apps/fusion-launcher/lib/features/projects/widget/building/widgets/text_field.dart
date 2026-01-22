import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../side_panel_widgets/schematic_properties.dart';

class BuildingPageTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const BuildingPageTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
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
          child: PropertyTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: hintText,
            fillColor: context.colorScheme.elevation2,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onSubmitted: onFieldSubmitted,
          ),
        ),
      ],
    );
  }
}
