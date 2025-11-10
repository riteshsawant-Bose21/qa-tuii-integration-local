import 'package:flutter/material.dart';

import '../datasource/pb_widgets.dart';
import '../dto/pb_item.dart';

class ItemWidgetBuilder extends StatelessWidget {
  const ItemWidgetBuilder({super.key, required this.item});
  final PBItem item;
  @override
  Widget build(BuildContext context) {
    return PbWidgets.getFor(item.type)?.builder(context, item) ?? const SizedBox();
  }
}
