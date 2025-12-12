import 'package:flutter/material.dart';

import '../../dto/pb_item.dart';
import '../../view/item_widget_builder.dart';

class PBEmpty extends StatelessWidget {
  const PBEmpty({super.key, required this.item, this.handler});
  final PBItem item;
  final PBWidgetValueHandler? handler;
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
