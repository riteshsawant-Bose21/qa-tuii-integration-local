import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/datasource/pb_widgets.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';

import '../data/algorithm_layout_data.dart';
import '../dto/pb_item_param.dart';
import '../dto/pb_layout.dart';

class PbcViewmodel extends ChangeNotifier {
  final Algorithm algorithm;
  PbcViewmodel({required this.algorithm}) {
    final PBLayout? layout = AlgorithmLayoutData.getForAlgorithm(algorithm.name);
    if (layout == null) return;
    for (final PBItem item in layout.children) {
      items.add(item);
    }
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

  void addItem(PbWidgets type, Offset position, Parameter data) {
    final PBItemParam param = type.fromParameter(data);
    final ({num height, num width}) size = switch (param) {
      PBIndicatorParam() => (width: 20, height: 15),
      PBSliderParam() => (width: 10, height: 25),
      PBSwitchParam() => (width: 20, height: 5),
      PBTextParam() => (width: 20, height: 20),
      PBGraphParam() => (width: 50, height: 50),

      _ => (width: 20, height: 20),
    };

    items.add(
      PBItem(
        id: Random().nextInt(999999).toString(),
        x: roundTo2Digit(position.dx),
        y: roundTo2Digit(position.dy),
        width: roundTo2Digit(size.width),
        height: roundTo2Digit(size.height),
        field: data.name,
        type: type.type,
        param: param,
        value: data.defaultValue,
      ),
    );
    selected = items.last;
    notifyListeners();
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
