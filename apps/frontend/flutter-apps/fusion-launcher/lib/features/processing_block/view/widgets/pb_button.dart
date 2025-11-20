import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_launcher/features/processing_block/view/common/neumorphic_container.dart';
import 'package:fusion_launcher/features/wiring_design/util/wiring_serialization_util.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBButton extends StatelessWidget {
  const PBButton({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;
  @override
  Widget build(BuildContext context) {
    final PBButtonParam data = (handler?.resolveForItem(item) ?? item.param) as PBButtonParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double mw = constraints.maxHeight;
        final bool value = WiringSerializationUtil.boolDeserializer.deserialize(handler?.getValue(item)) ?? false;
        return InkWell(
          onTap: () {
            handler?.onValueChanged(item, !value);
          },
          borderRadius: BorderRadius.circular(20),
          child: NeumorphicContainer(
            inner: value,
            child: Center(
              child: SvgPicture.asset(
                value ? data.enableValueIcon ?? "assets/svg/volume.svg" : data.disabledValueIcon ?? "assets/svg/volume.svg",
                height: mw * 0.5,
                color: value ? Colors.black : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
