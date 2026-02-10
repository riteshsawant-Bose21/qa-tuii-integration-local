import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

import '../../common/neumorphic_button.dart';

class NeumorphicGainTextField extends StatefulWidget {
  final double? controllerValue;
  final ValueChanged<double>? onSubmitted;
  final double height;
  final double width;
  final double borderRadius;
  final double maxGain;
  final double minGain;

  const NeumorphicGainTextField({
    super.key,
    required this.maxGain,
    required this.minGain,
    this.onSubmitted,
    this.height = 32,
    this.width = 84,
    this.borderRadius = 8,
    this.controllerValue,
  });

  @override
  State<NeumorphicGainTextField> createState() => _NeumorphicGainTextFieldState();
}

class _NeumorphicGainTextFieldState extends State<NeumorphicGainTextField> {
  late final TextEditingController controller = TextEditingController();

  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.controllerValue != null) controller.text = widget.controllerValue!.toString();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });

    controller.addListener(() {
      final String trimmedText = controller.text.trim();
      if (trimmedText.isEmpty || trimmedText.length == 1) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(NeumorphicGainTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllerValue != oldWidget.controllerValue) {
      if (widget.controllerValue != null) {
        controller.text = widget.controllerValue!.toString();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get hasValue => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.formControl(
      testId: SemanticHelper.createTestId(SemanticTypes.formControl, "neumorphic_gain_text_field"),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: isFocused ? null : getNeumorphismBoxShadows(inner: true),
            border: isFocused ? Border.all(color: Colors.black12, width: 1.5) : null,
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            focusNode: _focusNode,
            style: Theme.of(context).textTheme.labelLarge,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$'))],
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              suffixText: hasValue ? "db" : null,
              isDense: true,
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
              contentPadding: const EdgeInsets.all(0).copyWith(right: hasValue ? 6 : 0),
            ),
            onSubmitted: (String value) {
              final double? gain = double.tryParse(value);

              if (gain != null) {
                if (gain > widget.maxGain) {
                  if (widget.controllerValue != null) controller.text = widget.controllerValue.toString();

                  return FusionToast.error(context, message: "Gain cannot be greater than ${widget.maxGain}db");
                } else if (gain < widget.minGain) {
                  if (widget.controllerValue != null) controller.text = widget.controllerValue.toString();
                  return FusionToast.error(context, message: "Gain cannot be less than ${widget.minGain}db");
                } else {
                  widget.onSubmitted?.call(gain);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
