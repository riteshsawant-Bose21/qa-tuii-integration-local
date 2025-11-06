import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_layout.dart';
import 'package:fusion_launcher/features/processing_block/sample_data/layout_data.dart';

import '../dto/pb_item_param.dart';

class PbcViewmodel extends ChangeNotifier {
  PbcViewmodel() {
    items.addAll(PBLayout.fromMap(SampleData.sampleData).children);
  }
  List<PBItem> items = <PBItem>[];

  PBItem? _selected;

  PBItem? get selected => _selected;

  set selected(PBItem? value) {
    _selected = value;
    notifyListeners();
  }

  void move(Offset delta) {
    final num x = selected?.x ?? 0;
    final num y = selected?.y ?? 0;
    final PBItem? oldValue = selected;
    if (oldValue == null) return;
    selected = selected?.copyWith(
      x: roundTo2Digit(x + delta.dx),
      y: roundTo2Digit(y + delta.dy),
    );

    items.remove(oldValue);
    items.add(selected!);
  }

  void resize(num width, num height) {
    final PBItem? oldValue = selected;
    if (oldValue == null) return;
    selected = selected?.copyWith(width: roundTo2Digit(width), height: roundTo2Digit(height));

    items.remove(oldValue);
    items.add(selected!);
  }

  void updateProperty(String key, String value) {
    final PBItem? oldValue = selected;
    if (oldValue == null) return;
    final Map<String, dynamic> current = oldValue.param.toMap();
    current[key] = value;
    selected = oldValue.copyWith(param: oldValue.param.loadMap(current));
    items.remove(oldValue);
    items.add(selected!);
  }

  void addItem(String type, Offset position) {
    final PBItemParam param = switch (type) {
      'indicator' => PBIndicatorParam(label: "Indicator"),
      'slider' => PBSliderParam(max: 100, min: 0, label: "Slider"),
      'switch' => PBSwitchParam(label: "", enableValueLabel: "Yes", disabledValueLabel: "No"),
      'text' => PBTextParam(label: "Text Goes Here"),
      'graph' => PBGraphParam(label: "Graph goes here"),

      _ => PBEmptyParam(),
    };
    final ({num height, num width}) size = switch (type) {
      'indicator' => (width: 20, height: 5),
      'slider' => (width: 10, height: 25),
      'switch' => (width: 20, height: 5),
      'text' => (width: 20, height: 20),
      'graph' => (width: 50, height: 50),

      _ => (width: 20, height: 20),
    };

    items.add(
      PBItem(
        id: Random().nextInt(999999).toString(),
        x: position.dx,
        y: position.dy,
        width: size.width,
        height: size.height,
        field: "",
        type: type,
        param: param,
      ),
    );
  }

  Map<String, dynamic> get currentJson => <String, dynamic>{"width": 100, "height": 100, "children": items.map((PBItem e) => e.toMap()).toList()};

  void delete() {
    items.remove(selected);
    selected = null;
  }

  num roundTo2Digit(num val) {
    return (val * 100).round() / 100;
  }
}
