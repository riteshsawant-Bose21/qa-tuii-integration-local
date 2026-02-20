import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBGraph extends StatelessWidget {
  const PBGraph({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;
  @override
  Widget build(BuildContext context) {
    final PBGraphParam data = item.param as PBGraphParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          color: Colors.grey,
          child: Center(
            child: Text(data.label, style: TextStyle(fontSize: (constraints.maxWidth * 0.1).clamp(15, 25))),
          ),
        );
      },
    );
  }
}
