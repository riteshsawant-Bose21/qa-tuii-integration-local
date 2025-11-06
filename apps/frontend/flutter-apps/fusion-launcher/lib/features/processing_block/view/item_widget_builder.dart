import 'dart:math';

import 'package:flutter/material.dart';

import '../dto/pb_item.dart';
import 'widgets/pb_empty.dart';
import 'widgets/pb_graph.dart';
import 'widgets/pb_indicator.dart';
import 'widgets/pb_meter.dart';
import 'widgets/pb_slider.dart';
import 'widgets/pb_switch.dart';
import 'widgets/pb_text.dart';

class ItemWidgetBuilder extends StatelessWidget {
  const ItemWidgetBuilder({super.key, required this.item});
  final PBItem item;
  @override
  Widget build(BuildContext context) {
    if (item.type == 'switch') return PBSwitch(item: item);
    if (item.type == 'indicator') return PBIndicator(item: item);
    if (item.type == 'empty') return PBEmpty(item: item);
    if (item.type == 'text') return PBText(item: item);
    if (item.type == 'slider') return PBSlider(item: item);
    if (item.type == 'graph') return PBGraph(item: item);
    if (item.type == 'meter') return PBMeter(item: item);

    return Container(color: Colors.primaries[Random().nextInt(Colors.primaries.length)], child: Text(item.toJson()));
  }
}
