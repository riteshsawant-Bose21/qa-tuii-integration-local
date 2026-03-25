import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:fusion_lib/fusion_lib.dart';

class NeumorphicGainTextField extends StatefulWidget {
  final double? controllerValue;
  final ValueChanged<double>? onSubmitted;
  final double height;
  final double width;
  final double borderRadius;
  final double maxGain;
  final double minGain;
  final bool showDbSuffix;
  final bool enabled;
  final bool showCursor;
  final Color? backgroundColor;
  final String semanticId;

  const NeumorphicGainTextField({
    super.key,
    required this.semanticId,
    required this.maxGain,
    required this.minGain,
    this.onSubmitted,
    this.height = 32,
    this.width = 84,
    this.borderRadius = 8,
    this.controllerValue,
    this.showDbSuffix = true,
    this.enabled = true,
    this.showCursor = true,
    this.backgroundColor,
  });

  @override
  State<NeumorphicGainTextField> createState() =>
      _NeumorphicGainTextFieldState();
}

class _NeumorphicGainTextFieldState extends State<NeumorphicGainTextField> {
  late final TextEditingController controller = TextEditingController();

  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.controllerValue != null)
      controller.text = widget.controllerValue!.toString();
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
      testId: SemanticHelper.createTestId(
        SemanticTypes.formControl,
        "neumorphic_gain_text_field",
      ),
      label: controller.text,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: FusionContainer(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          raised: false,
          color: widget.backgroundColor ?? context.colorScheme.elevation2,
          borderRadius: widget.borderRadius,
          child: TextField(
            showCursor: widget.showCursor,
            enabled: widget.enabled,
            controller: controller,
            textAlign: TextAlign.center,
            focusNode: _focusNode,
            style: Theme.of(context).textTheme.labelLarge,
            mouseCursor:
                widget.enabled
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.forbidden,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$')),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              suffixText: hasValue && widget.showDbSuffix ? "db" : null,
              isDense: true,
              filled: false,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colorScheme.greyLight,
              ),
              contentPadding: const EdgeInsets.all(
                0,
              ).copyWith(right: hasValue && widget.showDbSuffix ? 6 : 0),
            ),
            onSubmitted: (String value) {
              final double? gain = double.tryParse(value);

              if (gain != null) {
                if (gain > widget.maxGain) {
                  if (widget.controllerValue != null)
                    controller.text = widget.controllerValue.toString();

                  return FusionToast.error(
                    context,
                    message: "Gain cannot be greater than ${widget.maxGain}db",
                  );
                } else if (gain < widget.minGain) {
                  if (widget.controllerValue != null)
                    controller.text = widget.controllerValue.toString();
                  return FusionToast.error(
                    context,
                    message: "Gain cannot be less than ${widget.minGain}db",
                  );
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

class UnitNumberTextField extends StatefulWidget {
  final double? controllerValue;
  final ValueChanged<double>? onSubmitted;
  final double height;
  final double width;
  final double borderRadius;
  final double? max;
  final double? min;
  final String unit;
  final bool enabled;

  const UnitNumberTextField({
    super.key,
    this.max,
    this.min,
    this.unit = "",
    this.onSubmitted,
    this.height = 32,
    this.width = 84,
    this.borderRadius = 8,
    this.controllerValue,
    this.enabled = true,
  });

  @override
  State<UnitNumberTextField> createState() => _UnitNumberTextFieldState();
}

class _UnitNumberTextFieldState extends State<UnitNumberTextField> {
  late final TextEditingController controller = TextEditingController();

  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.controllerValue != null)
      controller.text = widget.controllerValue!.toString();
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
  void didUpdateWidget(UnitNumberTextField oldWidget) {
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
      testId: SemanticHelper.createTestId(
        SemanticTypes.formControl,
        "unit_text_field",
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: FusionContainer(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          raised: false,
          color: context.colorScheme.elevation2,
          borderRadius: widget.borderRadius,
          child: TextField(
            enabled: widget.enabled,
            mouseCursor:
                widget.enabled
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.forbidden,
            controller: controller,
            textAlign: TextAlign.center,
            focusNode: _focusNode,
            style: Theme.of(context).textTheme.labelLarge,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$')),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              suffixText: hasValue ? widget.unit : null,
              isDense: true,
              filled: false,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colorScheme.greyLight,
              ),
              contentPadding: const EdgeInsets.all(
                0,
              ).copyWith(right: hasValue ? 6 : 0),
            ),
            onSubmitted: (String value) {
              final double? gain = double.tryParse(value);

              if (gain != null) {
                if (widget.max != null && gain > widget.max!) {
                  if (widget.controllerValue != null)
                    controller.text = widget.controllerValue.toString();

                  return FusionToast.error(
                    context,
                    message:
                        "Value cannot be greater than ${widget.max}${widget.unit}",
                  );
                } else if (widget.min != null && gain < widget.min!) {
                  if (widget.controllerValue != null)
                    controller.text = widget.controllerValue.toString();
                  return FusionToast.error(
                    context,
                    message:
                        "Value cannot be less than ${widget.min}${widget.unit}",
                  );
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
