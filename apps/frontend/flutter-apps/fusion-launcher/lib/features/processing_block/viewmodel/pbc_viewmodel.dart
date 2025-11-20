import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/datasource/pb_widgets.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';

import '../data/algorithm_layout_data.dart';
import '../dto/pb_item_param.dart';
import '../dto/pb_layout.dart';

class PbcViewmodel extends ChangeNotifier {
  final Algorithm algorithm;

  final ScrollController scrollController = ScrollController();
  PbcViewmodel({required this.algorithm}) {
    final PBLayout? layout = AlgorithmLayoutData.getForAlgorithm(algorithm.name);
    if (layout == null) return;
    for (final PBItem item in layout.children) {
      items.add(item);
    }
    width = layout.width.toDouble();
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

  void addParameter(PbWidgets type, Offset position, Parameter data) {
    final dynamic dimension = data.dimensions?.isNotEmpty == true ? getValue(data.dimensions!.first) : null;
    final PBItemParam param = type.fromParameter(data);
    final ({num height, num width}) size = switch (param) {
      PBIndicatorParam() => (width: 20, height: 15),
      PBSliderParam() => (width: 10, height: 25),
      PBSwitchParam() => (width: 20, height: 5),
      PBTextParam() => (width: 20, height: 20),
      PBGraphParam() => (width: 50, height: 50),

      _ => (width: 20, height: 20),
    };
    final num noOfItems = dimension is num && dimension > 1 ? dimension : 1;
    final num paramWidth = roundTo2Digit(size.width);
    num currentDx = roundTo2Digit(position.dx) - paramWidth;
    num currentY = roundTo2Digit(position.dy);
    for (int i = 0; i < noOfItems; i++) {
      currentDx += paramWidth;
      if (currentDx + paramWidth > width) {
        currentDx = roundTo2Digit(position.dx);
        currentY += roundTo2Digit(size.height) + 5;
      }
      items.add(
        PBItem(
          id: Random().nextInt(999999).toString(),
          x: currentDx,
          y: currentY,
          width: roundTo2Digit(size.width),
          height: roundTo2Digit(size.height),
          field: data.name,
          type: type.type,
          param: param,
          dimension: noOfItems > 1 ? i : null,
          value: data.defaultValue,
        ),
      );
    }
    selected = items.last;
    notifyListeners();
  }

  void addTelemetry(PbWidgets type, Offset position, Telemetry data) {
    final PBItemParam param = type.fromTelemetry(data);
    final ({num height, num width}) size = switch (param) {
      PBIndicatorParam() => (width: 20, height: 15),
      PBSliderParam() => (width: 10, height: 25),
      PBTextfieldParam() => (width: 20, height: 15),
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

  double width = 200;
  void addExtraWidth() {
    width += 20;
    notifyListeners();
  }

  void reduceWidth() {
    width -= 20;
    notifyListeners();
  }

  Map<String, dynamic> get currentJson => <String, dynamic>{"width": width, "height": 100, "children": items.map((PBItem e) => e.toMap()).toList()};

  void delete() {
    items.remove(selected);
    selected = null;
  }

  num roundTo2Digit(num val) {
    return (val * 100).round() / 100;
  }

  dynamic getValue(dynamic val) {
    if (val is String) {
      return algorithm.properties?.firstWhereOrNull((Property element) => element.name == val)?.defaultValue ?? val;
    }
    return val;
  }
}
