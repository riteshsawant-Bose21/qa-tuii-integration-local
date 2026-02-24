import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../dto/pb_item_param.dart';
import '../../view/item_widget_builder.dart';

class PBText extends StatelessWidget {
  const PBText({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;
  @override
  Widget build(BuildContext context) {
    final PBTextParam data = item.param as PBTextParam;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Text(
            data.label,
            style: TextStyle(
              fontSize: (constraints.maxHeight * 0.1).clamp(15, 25),
            ),
          ),
        );
      },
    );
  }
}
