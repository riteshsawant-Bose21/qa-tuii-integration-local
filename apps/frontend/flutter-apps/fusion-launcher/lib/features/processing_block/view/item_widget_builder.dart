import 'package:flutter/material.dart';

import '../datasource/pb_widgets.dart';
import '../dto/pb_item.dart';
import '../dto/pb_item_param.dart';

class ItemWidgetBuilder extends StatelessWidget {
  const ItemWidgetBuilder({super.key, required this.item, this.valueHandler});
  final PBItem item;
  final PBWidgetValueHandler? valueHandler;
  @override
  Widget build(BuildContext context) {
    return PbWidgets.getFor(item.type)?.builder(context, item, valueHandler) ?? const SizedBox();
  }
}

abstract class PBWidgetValueHandler {
  void onValueChanged(PBItem item, dynamic value);

  dynamic getValue(String param);

  PBItemParam resolveForItem(PBItem item);
}
