// ─────────────────────────────────────────────────────────────
// 3. FusionBorderedTextField
//
// Rounded bordered container holding a FusionTextField with
// no internal borders, hover background, and zero padding.
// Drop-in replacement for the repeated bordered-input pattern.
//
// Usage:
//   FusionBorderedTextField(
//     controller: _ctrl,
//     hintText: 'Enter zone name',
//     semanticId: 'zone_name',
//     onChanged: (v) => ...,
//   )
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

class FusionBorderedTextField extends StatefulWidget {
  const FusionBorderedTextField({
    super.key,
    this.controller,
    required this.semanticId,
    this.hintText = 'Enter value',
    this.maxLength,
    this.onChanged,
    this.contentPadding = const EdgeInsets.all(16),
    this.leading,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String semanticId;
  final String hintText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry contentPadding;
  final List<TextInputFormatter>? inputFormatters;

  /// Optional widget placed at the start of the row (e.g. a FusionColorDot).
  final Widget? leading;

  @override
  State<FusionBorderedTextField> createState() => _FusionBorderedTextFieldState();
}

class _FusionBorderedTextFieldState extends State<FusionBorderedTextField> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.formControl(
      testId: SemanticHelper.createTestId(SemanticTypes.textInput, widget.semanticId),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
            color: _hovering ? context.colorScheme.elevation2 : Colors.transparent,
          ),
          padding: widget.contentPadding,
          child: Row(
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FusionTextField(
                  maxLength: widget.maxLength ?? 20,
                  semanticFieldId: '${widget.semanticId}_input',
                  controller: widget.controller,
                  hintText: widget.hintText,
                  inputFormatters: widget.inputFormatters,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
                    labelStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
