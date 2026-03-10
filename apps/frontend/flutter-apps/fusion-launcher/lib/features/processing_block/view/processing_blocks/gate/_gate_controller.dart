part of 'gate_block.dart';

class GateController {
  final AlgorithmDataViewmodel valueHandler;
  GateController(this.valueHandler);

  List<PropertySetting> get allProperties {
    return valueHandler.processingBlock.properties;
  }

  void bypassGlobally(bool value) {
    valueHandler.updateValue(field: 'bypass', value: value);
  }

  bool get isGloballyBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  }

  /// Updates the band type (e.g., milliseconds or seconds) in the processing block's properties.
  void updateThreshold(num value) {
    valueHandler.updateValue(field: 'threshold', value: roundTo2Digits(value));
  }

  num? get threshold {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'threshold' && e.dimension == null)?.value,
    );
  }

  void updateRange(num value) {
    valueHandler.updateValue(field: 'range', value: roundTo2Digits(value));
  }

  num? get range {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'range' && e.dimension == null)?.value,
    );
  }

  void updateAttack(num value) {
    valueHandler.updateValue(field: 'attack', value: roundTo2Digits(value));
  }

  num? get attack {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'attack' && e.dimension == null)?.value,
    );
  }

  void updateHold(num value) {
    valueHandler.updateValue(field: 'hold', value: roundTo2Digits(value));
  }

  num? get hold {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'hold' && e.dimension == null)?.value,
    );
  }

  void updateDecay(num value) {
    valueHandler.updateValue(field: 'decay', value: roundTo2Digits(value));
  }

  num? get decay {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'decay' && e.dimension == null)?.value,
    );
  }

  num roundTo2Digits(num value) {
    return (value * 100).round() / 100;
  }

  List<GraphPoint> getGraphPoints() {
    final num threshold = this.threshold ?? 0;
    final num range = this.range ?? 0;
    final num minX = -80;
    final num maxX = 0;
    final num minY = -80;
    final num maxY = 0;
    num tempX = minX - range;
    if (tempX > threshold) {
      tempX = threshold;
    }
    num tempY = threshold + range;
    if (tempY < minY) {
      tempY = minY;
    }
    //  num[] posX = <num>{ tempX, threshold, threshold, maxX };
    //             num[] posY = <num>{ minY, tempY, threshold, maxY };
    return <GraphPoint>[
      GraphPoint(x: tempX, y: minY),
      GraphPoint(x: threshold, y: tempY, isDraggable: true),
      GraphPoint(x: threshold, y: threshold, isDraggable: true),
      GraphPoint(x: maxX, y: maxY),
    ];
  }

  void onGraphPointChanged(int index, num value, DragDirection direction) {
    final num currentThreshold = threshold ?? -40;
    final num currentRange = range ?? 40;
    switch (index) {
      case 1: // Gate opening point (range control)
        if (direction == DragDirection.horizontal) {
          // Update range by changing the distance from threshold
          // final num newRange = -currentThreshold + value;
          // updateRange(newRange.clamp(-70, 0));
        } else if (direction == DragDirection.vertical) {
          // Vertical movement affects the range by changing the attenuation level
          final num newRange = -currentThreshold + value;
          updateRange(newRange.clamp(-70, 0));
        }
        break;

      case 2: // Threshold point
        if (direction == DragDirection.horizontal) {
          updateThreshold(value.clamp(-80, 0));
        } else if (direction == DragDirection.vertical) {
          updateThreshold(value.clamp(-80, 0));
        }
        break;

      default:
        // Points 0 and 3 are not draggable (fixed endpoints)
        break;
    }
  }
}

class GraphPoint {
  final num x;
  final num y;
  final bool isDraggable;
  GraphPoint({
    this.isDraggable = false,
    required this.x,
    required this.y,
  });
}

enum DragDirection {
  horizontal,
  vertical,
}
