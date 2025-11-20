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

  List<PBItem> _selectedItems = <PBItem>[];
  List<PBItem> get selectedItems => _selectedItems;
  bool isShiftPressed = false;
  void setSelected(
    PBItem item,
  ) {
    if (!isShiftPressed) {
      _selectedItems.clear();
    }
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
    _selected = _selectedItems.lastOrNull;
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    _selected = null;
    notifyListeners();
  }

  PBItem? get selected => _selected;

  void move(Offset delta) {
    if (_selectedItems.isEmpty) return;

    for (final PBItem item in _selectedItems) {
      final num x = item.x;
      final num y = item.y;
      final PBItem oldValue = item;
      final PBItem newValue = item.copyWith(
        x: roundTo2Digit(x + delta.dx),
        y: roundTo2Digit(y + delta.dy),
      );
      items.remove(oldValue);
      items.add(newValue);
      _selectedItems.remove(oldValue);
      _selectedItems.add(newValue);
    }
    // update selected items with new values
    final List<PBItem> newSelection = <PBItem>[];
    for (final PBItem oldItem in _selectedItems) {
      final PBItem? newItem = items.firstWhereOrNull((PBItem e) => e.id == oldItem.id);
      if (newItem != null) {
        newSelection.add(newItem);
      }
    }
    _selectedItems = newSelection;
    _selected = _selectedItems.lastOrNull;
    notifyListeners();
  }

  void resize(num? width, num? height) {
    for (final PBItem oldValue in _selectedItems) {
      final PBItem selected = oldValue.copyWith(width: width != null ? roundTo2Digit(width) : null, height: height != null ? roundTo2Digit(height) : null);

      items.remove(oldValue);
      items.add(selected);
      _selectedItems.remove(oldValue);
      _selectedItems.add(selected);
    }
    notifyListeners();
  }

  void updateProperty(String key, String value) {
    for (final PBItem oldValue in _selectedItems) {
      final Map<String, dynamic> current = oldValue.param.toMap();
      current[key] = value;
      final PBItem selected = oldValue.copyWith(param: oldValue.param.loadMap(current));
      items.remove(oldValue);
      items.add(selected);
      _selectedItems.remove(oldValue);
      _selectedItems.add(selected);
    }
    notifyListeners();
  }

  void addParameter(PbWidgets type, Offset position, Parameter data) {
    final dynamic dimension = data.dimensions?.isNotEmpty == true ? getValue(data.dimensions!.first) : null;
    final PBItemParam param = type.fromParameter(data);
    final ({num height, num width}) size = switch (param) {
      PBIndicatorParam() => (width: 20, height: 15),
      PBSliderParam() => (width: 10, height: 25),
      PBTextfieldParam() => (width: 10, height: 5),
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
    setSelected(items.last);
    notifyListeners();
  }

  void addTelemetry(PbWidgets type, Offset position, Telemetry data) {
    final PBItemParam param = type.fromTelemetry(data);
    final ({num height, num width}) size = switch (param) {
      PBIndicatorParam() => (width: 20, height: 15),
      PBSliderParam() => (width: 10, height: 25),
      PBTextfieldParam() => (width: 15, height: 5),
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
    setSelected(items.last);
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
    for (final PBItem item in _selectedItems) {
      items.remove(item);
    }
    clearSelection();
    notifyListeners();
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

  Future<void> saveLayout() async {
    final PBLayout layout = PBLayout(
      width: width,
      height: 100,
      children: items,
    );
    await AlgorithmLayoutData.saveLayout(algorithm.name, layout);
  }
}
