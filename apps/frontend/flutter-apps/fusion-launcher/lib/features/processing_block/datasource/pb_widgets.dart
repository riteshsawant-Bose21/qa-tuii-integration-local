import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/view/widgets/pb_meter.dart';

import '../dto/pb_item_param.dart';
import '../view/widgets/widgets.dart';

class PbWidgets {
  final String type;
  final Widget Function(BuildContext context, PBItem item) builder;
  final PBItemParam Function(Map<dynamic, dynamic> map) paramFactory;
  final PBItemParam Function(Parameter data) fromParameter;

  PbWidgets({required this.type, required this.builder, required this.paramFactory, required this.fromParameter});

  static List<PbWidgets> floatWidgets = <PbWidgets>[
    PbWidgets(
      type: 'slider',
      builder: (BuildContext context, PBItem item) => PBSlider(item: item),
      paramFactory: PBSliderParam.fromMap,
      fromParameter: (Parameter data) => PBSliderParam(label: data.name, min: 0, max: 100),
    ),
    PbWidgets(
      type: 'meter',
      builder: (BuildContext context, PBItem item) => PBMeter(item: item),
      paramFactory: PBMeterParam.fromMap,
      fromParameter: (Parameter data) => PBMeterParam(label: data.name, max: 100, min: 0),
    ),
  ];

  static List<PbWidgets> boolWidgets = <PbWidgets>[
    PbWidgets(
      type: 'indicator',
      builder: (BuildContext context, PBItem item) => PBIndicator(item: item),
      paramFactory: PBIndicatorParam.fromMap,
      fromParameter: (Parameter data) => PBIndicatorParam(label: data.name),
    ),
    PbWidgets(
      type: 'switch',
      builder: (BuildContext context, PBItem item) => PBSwitch(item: item),
      paramFactory: PBSwitchParam.fromMap,
      fromParameter: (Parameter data) => PBSwitchParam(label: data.name, enableValueLabel: 'YES', disabledValueLabel: 'NO'),
    ),
  ];

  static List<PbWidgets> genericWidgets = <PbWidgets>[
    // PbWidgets(
    //   type: 'empty',
    //   builder: (BuildContext context, PBItem item) => PBEmpty(item: item),
    //   paramFactory: PBEmptyParam.fromMap,
    //   fromParameter: (Parameter data) => PBEmptyParam(),
    // ),
    PbWidgets(
      type: 'text',
      builder: (BuildContext context, PBItem item) => PBText(item: item),
      paramFactory: PBTextParam.fromMap,
      fromParameter: (Parameter data) => PBTextParam(label: data.name),
    ),
    // PbWidgets(
    //   type: 'graph',
    //   builder: (BuildContext context, PBItem item) => PBGraph(item: item),
    //   paramFactory: PBGraphParam.fromMap,
    //   fromParameter: (Parameter data) => PBGraphParam(label: data.name),
    // ),
    // PbWidgets(
    //   type: 'radio',
    //   builder: (BuildContext context, PBItem item) => PBRadio(item: item),
    //   paramFactory: PBRadioParam.fromMap,
    // ),
  ];

  static List<PbWidgets> all = <PbWidgets>[
    ...floatWidgets,
    ...boolWidgets,
    ...genericWidgets,
    // PbWidgets(
    //   type: 'switch',
    //   builder: (BuildContext context, PBItem item) => PBSwitch(item: item),
    //   paramFactory: PBSwitchParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'indicator',
    //   builder: (BuildContext context, PBItem item) => PBIndicator(item: item),
    //   paramFactory: PBIndicatorParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'empty',
    //   builder: (BuildContext context, PBItem item) => PBEmpty(item: item),
    //   paramFactory: PBEmptyParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'text',
    //   builder: (BuildContext context, PBItem item) => PBText(item: item),
    //   paramFactory: PBTextParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'slider',
    //   builder: (BuildContext context, PBItem item) => PBSlider(item: item),
    //   paramFactory: PBSliderParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'graph',
    //   builder: (BuildContext context, PBItem item) => PBGraph(item: item),
    //   paramFactory: PBGraphParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'meter',
    //   builder: (BuildContext context, PBItem item) => PBMeter(item: item),
    //   paramFactory: PBMeterParam.fromMap,
    // ),
    // PbWidgets(
    //   type: 'radio',
    //   builder: (BuildContext context, PBItem item) => PBRadio(item: item),
    //   paramFactory: PBMeterParam.fromMap,
    // ),
  ];

  static PbWidgets? getFor(String type) {
    return all.firstWhereOrNull((PbWidgets e) => e.type == type);
  }
}
