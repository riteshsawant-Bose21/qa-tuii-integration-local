import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:fusion_lib/fusion_lib.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../item_widget_builder.dart';

class PBItemTextfield extends StatelessWidget {
  const PBItemTextfield({
    super.key,
    required this.item,
    this.showIntervals = true,
    this.handler,
  });

  final PBItem item;
  final bool showIntervals;
  final PBWidgetValueHandler? handler;

  @override
  Widget build(BuildContext context) {
    final PBTextfieldParam data =
        (handler?.resolveForItem(item) ?? item.param) as PBTextfieldParam;

    return SemanticHelper.textInput(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "PB_TextField",
      ),
      label: data.label,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final num? value = DeserializationUtil.numDeserializer.deserialize(
            handler?.getValue(item) ?? item.value,
          );
          final double widthPerCell = constraints.maxWidth / item.width;
          return FusionContainer(
            raised: false,
            // radius: widthPerCell * 2,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(
                child: TextFormField(
                  key: ValueKey<String>(
                    '${item.id}_textfield${value?.toString() ?? ''}',
                  ),

                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    fillColor: Colors.transparent,

                    filled: true,
                    // contentPadding: EdgeInsets.symmetric(horizontal: widthPerCell * 0.2, vertical: widthPerCell * 0.1),
                    hintText: data.label,
                    // suffixText: data.unit ?? '',
                    // isDense: true,
                    // isCollapsed: true,
                  ),
                  style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.top,
                  initialValue: value?.toString() ?? '',
                  keyboardType: TextInputType.number,

                  onFieldSubmitted: (String value) {
                    final num? parsedValue = num.tryParse(value);
                    if (parsedValue != null) {
                      handler?.onValueChanged(
                        item,
                        parsedValue.clamp(data.min, data.max),
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PBNumberTextField extends StatelessWidget {
  const PBNumberTextField({
    super.key,
    this.value,
    required this.onChanged,
    this.min,
    this.max,
  });
  final num? value;
  final ValueChanged<num> onChanged;
  final num? min;
  final num? max;
  @override
  Widget build(BuildContext context) {
    return PBTextField(
      value: value?.toString(),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
      ],
      onChanged: (String value) {
        final num? parsedValue = num.tryParse(value);
        if (parsedValue != null) {
          if (min != null && max != null) {
            onChanged(parsedValue.clamp(min!, max!));
          } else {
            onChanged(parsedValue);
          }
        }
      },
    );
  }
}

class PBTextField extends StatefulWidget {
  const PBTextField({
    super.key,
    required this.value,
    this.onChanged,
    this.inputFormatters,
  });
  final String? value;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<PBTextField> createState() => _PBTextFieldState();
}

class _PBTextFieldState extends State<PBTextField> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    controller.text = widget.value ?? '';
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        controller.text = widget.value ?? '';
      }
    });
  }

  @override
  void didUpdateWidget(covariant PBTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      controller.text = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      alignment: Alignment.center,
      color: context.colorScheme.elevation2,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: TextFormField(
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          controller: controller,
          style: context.textTheme.bodySmall,
          inputFormatters: widget.inputFormatters,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
            hintText: '',
            contentPadding: EdgeInsets.all(0),
            isCollapsed: true,
            isDense: true,
          ),
          onFieldSubmitted: (String value) {
            widget.onChanged?.call(value);
          },
          onTapOutside: (PointerDownEvent event) {
            controller.text = widget.value ?? '';
          },
        ),
      ),
    );
  }
}
