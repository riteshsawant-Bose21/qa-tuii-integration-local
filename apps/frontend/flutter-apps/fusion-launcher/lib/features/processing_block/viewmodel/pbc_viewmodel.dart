// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/algorithm/algorithm_metadata.dart';
import 'package:fusion_launcher/features/processing_block/datasource/pb_widgets.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';

import '../../wiring_design/controller/state_stack.dart';
import '../data/algorithm_layout_data.dart';
import '../dto/pb_item_param.dart';
import '../dto/pb_layout.dart';

class PbcViewmodel extends ChangeNotifier {
  final Algorithm algorithm;

  final ScrollController scrollController = ScrollController();
  PbcViewmodel({required this.algorithm}) {
    final PBLayout? layout = AlgorithmLayoutData.getForAlgorithm(algorithm.name);
    if (layout == null) return;
    final List<PBItem> items = <PBItem>[];
    for (final PBItem item in layout.children) {
      items.add(item);
    }
    _setState(PBCState(items: items, selectedItems: <String>[]));
    width = layout.width.toDouble();
  }
  PBCState state = PBCState(items: <PBItem>[], selectedItems: <String>[]);

  List<PBItem> get items => state.items;
  List<PBItem> get selectedItems => state.items.where((PBItem item) => state.selectedItems.contains(item.id)).toList();

  StateStack stack = StateStack();

  bool isShiftPressed = false;

  void _setState(PBCState newState) {
    stack.push(state.toMap());
    state = newState;

    notifyListeners();
  }

  void undo() {
    final Map<String, dynamic>? previousState = stack.undo();
    if (previousState != null) {
      state = PBCState.fromMap(previousState);
      notifyListeners();
    }
  }

  void redo() {
    final Map<String, dynamic>? nextState = stack.redo();
    if (nextState != null) {
      state = PBCState.fromMap(nextState);
      notifyListeners();
    }
  }

  void setSelected(PBItem item) {
    _setState(state.select(item, isShiftPressed: isShiftPressed));
  }

  void clearSelection() {
    _setState(state.clearSelectedItems());
  }

  void move(Offset delta) {
    final List<PBItem> selectedItems = this.selectedItems;
    if (selectedItems.isEmpty) return;
    print("Delta: $delta");
    final List<PBItem> items = <PBItem>[];
    for (final PBItem item in selectedItems) {
      final num x = item.x;
      final num y = item.y;
      final PBItem oldValue = item;
      final PBItem newValue = item.copyWith(
        x: roundTo2Digit(x + delta.dx),
        y: roundTo2Digit(y + delta.dy),
      );
      items.add(newValue);
    }

    _setState(state.updateItems(items));
  }

  void resize(num? width, num? height) {
    final List<PBItem> selectedItems = this.selectedItems;
    final List<PBItem> items = <PBItem>[];
    for (final PBItem oldValue in selectedItems) {
      final PBItem selected = oldValue.copyWith(width: width != null ? roundTo2Digit(width) : null, height: height != null ? roundTo2Digit(height) : null);

      items.remove(oldValue);
      items.add(selected);
    }
    _setState(state.updateItems(items));
  }

  void updateProperty(String key, String value) {
    final List<PBItem> selectedItems = this.selectedItems;
    final List<PBItem> items = <PBItem>[];
    for (final PBItem oldValue in selectedItems) {
      final Map<String, dynamic> current = oldValue.param.toMap();
      current[key] = value;
      final PBItem selected = oldValue.copyWith(param: oldValue.param.loadMap(current));
      items.remove(oldValue);
      items.add(selected);
    }
    _setState(state.updateItems(items));
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
    final List<PBItem> pbItems = <PBItem>[];
    for (int i = 0; i < noOfItems; i++) {
      currentDx += paramWidth;
      if (currentDx + paramWidth > width) {
        currentDx = roundTo2Digit(position.dx);
        currentY += roundTo2Digit(size.height) + 5;
      }
      pbItems.add(
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
    _setState(
      (state
          .addItem(
            pbItems,
          )
          .select(pbItems.first)),
    );
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

    final PBItem pbItem = PBItem(
      id: Random().nextInt(999999).toString(),
      x: roundTo2Digit(position.dx),
      y: roundTo2Digit(position.dy),
      width: roundTo2Digit(size.width),
      height: roundTo2Digit(size.height),
      field: data.name,
      type: type.type,
      param: param,
      value: data.defaultValue,
    );

    _setState(
      state.addItem(
        <PBItem>[pbItem],
      ),
    );
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

  Map<String, dynamic> get currentJson => <String, dynamic>{"width": width, "height": 100, "children": state.items.map((PBItem e) => e.toMap()).toList()};

  void delete() {
    _setState(state.remove(selectedItems).clearSelectedItems());
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
      children: state.items,
    );
    await AlgorithmLayoutData.saveLayout(algorithm.name, layout);
  }
}

class PBCState {
  final List<PBItem> items;
  final List<String> selectedItems;

  PBCState({
    required this.items,
    required this.selectedItems,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'items': items.map((PBItem x) => x.toMap()).toList(),
      'selectedItems': selectedItems,
    };
  }

  factory PBCState.fromMap(Map<String, dynamic> map) {
    return PBCState(
      items: List<PBItem>.from(
        (map['items'] as List<Map<String, dynamic>>).map<PBItem>(
          (Map<String, dynamic> x) => PBItem.fromMap(x),
        ),
      ),
      selectedItems: List<String>.from((map['selectedItems'] ?? const <String>[]) as List<String>),
    );
  }

  String toJson() => json.encode(toMap());

  factory PBCState.fromJson(String source) => PBCState.fromMap(json.decode(source) as Map<String, dynamic>);
}

extension PBCStateMethods on PBCState {
  PBCState copyWith({
    List<PBItem>? items,
    List<String>? selectedItems,
  }) {
    return PBCState(
      items: items ?? this.items,
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }

  PBCState clearSelection() {
    return copyWith(selectedItems: <String>[]);
  }

  PBCState select(PBItem item, {bool isShiftPressed = false}) {
    final List<String> newSelectedItems = List<String>.from(selectedItems);
    if (!isShiftPressed) {
      newSelectedItems.clear();
    }
    if (newSelectedItems.contains(item.id)) {
      newSelectedItems.remove(item.id);
    } else {
      newSelectedItems.add(item.id);
    }
    return copyWith(selectedItems: newSelectedItems);
  }

  PBCState clearSelectedItems() {
    return copyWith(selectedItems: <String>[]);
  }

  PBCState updateItems(List<PBItem> updatedItems) {
    final List<PBItem> newItems = <PBItem>[];
    for (final PBItem element in items) {
      final PBItem? firstWhereOrNull = updatedItems.firstWhereOrNull((PBItem item) => item.id == element.id);
      if (firstWhereOrNull != null) {
        newItems.add(firstWhereOrNull);
      } else {
        newItems.add(element);
      }
    }

    return copyWith(items: newItems, selectedItems: selectedItems);
  }

  PBCState addItem(List<PBItem> item) {
    final List<PBItem> newItems = List<PBItem>.from(items)..addAll(item);
    return copyWith(items: newItems, selectedItems: item.map((PBItem e) => e.id).toList());
  }

  PBCState remove(List<PBItem> itemsToRemove) {
    final List<PBItem> newItems = List<PBItem>.from(items)..removeWhere((PBItem item) => itemsToRemove.contains(item));
    final List<String> newSelectedItems = List<String>.from(selectedItems)
      ..removeWhere((String item) => itemsToRemove.any((PBItem removeItem) => removeItem.id == item));
    return copyWith(items: newItems, selectedItems: newSelectedItems);
  }
}
