import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BuildingPageTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Color? fillColor;

  const BuildingPageTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.fillColor,
  });

  @override
  State<BuildingPageTextField> createState() => _BuildingPageTextFieldState();
}

class _BuildingPageTextFieldState extends State<BuildingPageTextField> {
  TextEditingController? _internalController;
  TextEditingController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _internalController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant BuildingPageTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔁 Case 1: External controller added
    if (oldWidget.controller == null && widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }

    // 🔁 Case 2: External controller removed
    if (oldWidget.controller != null && widget.controller == null) {
      _internalController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: widget.label,
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
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: widget.hintText,
              fillColor: widget.fillColor ?? context.colorScheme.elevation2,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onSubmitted: widget.onFieldSubmitted,
              onTapOutside: (PointerDownEvent event) {
                widget.onFieldSubmitted?.call(_controller.text);
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}
