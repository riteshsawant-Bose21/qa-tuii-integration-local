import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';

import '../dto/pb_item_param.dart';
import '../view/widgets/pb_empty.dart';
import '../view/widgets/pb_graph.dart';
import '../view/widgets/pb_indicator.dart';
import '../view/widgets/pb_slider.dart';
import '../view/widgets/pb_switch.dart';
import '../view/widgets/pb_text.dart';

class PbWidgets {
  final String type;
  final Widget Function(BuildContext context, PBItem item) builder;
  final PBItemParam Function(Map<String, dynamic> map) paramFactory;

  PbWidgets({required this.type, required this.builder, required this.paramFactory});

  static List<PbWidgets> all = <PbWidgets>[
    PbWidgets(
      type: 'switch',
      builder: (BuildContext context, PBItem item) => PBSwitch(item: item),
      paramFactory: PBSwitchParam.fromMap,
    ),
    PbWidgets(
      type: 'indicator',
      builder: (BuildContext context, PBItem item) => PBIndicator(item: item),
      paramFactory: PBIndicatorParam.fromMap,
    ),
    PbWidgets(
      type: 'empty',
      builder: (BuildContext context, PBItem item) => PBEmpty(item: item),
      paramFactory: PBEmptyParam.fromMap,
    ),
    PbWidgets(
      type: 'text',
      builder: (BuildContext context, PBItem item) => PBText(item: item),
      paramFactory: PBTextParam.fromMap,
    ),
    PbWidgets(
      type: 'slider',
      builder: (BuildContext context, PBItem item) => PBSlider(item: item),
      paramFactory: PBSliderParam.fromMap,
    ),
    PbWidgets(
      type: 'graph',
      builder: (BuildContext context, PBItem item) => PBGraph(item: item),
      paramFactory: PBGraphParam.fromMap,
    ),
  ];

  static PbWidgets? getFor(String type) {
    return all.firstWhereOrNull((PbWidgets e) => e.type == type);
  }
}
