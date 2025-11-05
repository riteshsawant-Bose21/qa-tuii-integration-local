import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';

import '../dto/pb_item_param.dart';

class PbcViewmodel extends ChangeNotifier {
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
      x: x + delta.dx,
      y: y + delta.dy,
    );

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
}
