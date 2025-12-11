import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/view/common/neumorphic_container.dart';
import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../item_widget_builder.dart';

class PBTextfield extends StatelessWidget {
  const PBTextfield({
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
    final PBTextfieldParam data = (handler?.resolveForItem(item) ?? item.param) as PBTextfieldParam;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final num? value = WiringSerializationUtil.numDeserializer.deserialize(handler?.getValue(item) ?? item.value);
        final double widthPerCell = constraints.maxWidth / item.width;
        return NeumorphicContainer(
          inner: true,
          radius: widthPerCell * 2,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(widthPerCell),
                child: TextFormField(
                  key: ValueKey<String>('${item.id}_textfield${value?.toString() ?? ''}'),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: widthPerCell * 0.2, vertical: widthPerCell * 0.1),
                    hintText: data.label,
                    suffixText: data.unit ?? '',
                    isDense: true,
                    isCollapsed: true,
                  ),
                  style: TextStyle(
                    fontSize: widthPerCell * 2,
                  ),
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.top,
                  initialValue: value?.toString() ?? '',
                  keyboardType: TextInputType.number,

                  onFieldSubmitted: (String value) {
                    final num? parsedValue = num.tryParse(value);
                    if (parsedValue != null) {
                      handler?.onValueChanged(item, parsedValue.clamp(data.min, data.max));
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
