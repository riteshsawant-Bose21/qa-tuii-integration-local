part of 'compressor_block.dart';

class CompressorController {
  final AlgorithmDataViewmodel valueHandler;
  CompressorController(this.valueHandler);

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

  void updateReduction(num value) {
    valueHandler.updateValue(field: 'reduction', value: roundTo2Digits(value));
  }

  num? get reduction {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'reduction' && e.dimension == null)?.value,
    );
  }

  /// Updates the band type (e.g., milliseconds or seconds) in the processing block's properties.
  void updateRatio(num value) {
    valueHandler.updateValue(field: 'ratio', value: roundTo2Digits(value));
  }

  /// Retrieves the current band type from the processing block's properties.
  num? get ratio {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'ratio' && e.dimension == null)?.value,
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

  void updateRelease(num value) {
    valueHandler.updateValue(field: 'release', value: roundTo2Digits(value));
  }

  num? get release {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'release' && e.dimension == null)?.value,
    );
  }

  num roundTo2Digits(num value) {
    return (value * 100).round() / 100;
  }

  List<GraphPoint> getGraphPoints() {
    final num threshold = this.threshold ?? 0;
    final num ratio = this.ratio ?? 0;
    final num minX = -60;
    final num maxX = 0;
    final num minY = -60;
    final num maxY = 0;

    //  num[] posX = <num>{ tempX, threshold, threshold, maxX };
    //             num[] posY = <num>{ minY, tempY, threshold, maxY };
    return <GraphPoint>[
      GraphPoint(x: minX, y: minY),
      GraphPoint(x: threshold, y: threshold, isDraggable: true),
      GraphPoint(x: maxX, y: threshold + threshold.abs() / ratio, isDraggable: true),
    ];
  }

  void onGraphPointChanged(int index, num value, DragDirection direction) {
    final num currentThreshold = threshold ?? -40;
    switch (index) {
      case 1: // Gate opening point (range control)
        final num newThreshold = value;
        updateThreshold(newThreshold.clamp(-60, 0));
        break;

      case 2: // Threshold point
        if (direction == DragDirection.horizontal) {
          // updateRatio(value.clamp(-80, 0));
        } else if (direction == DragDirection.vertical) {
          // Calculate ratio from the dragged y-position
          // From the formula: y = threshold + threshold.abs() / ratio
          // Solving for ratio: ratio = threshold.abs() / (y - threshold)
          final num currentThresholdValue = threshold ?? -40;
          final num deltaY = value - currentThresholdValue;
          if (deltaY.abs() > 0.01) {
            // Avoid division by zero
            final num newRatio = currentThresholdValue.abs() / deltaY;
            updateRatio(newRatio.clamp(1.0, 20.0)); // Typical compressor ratio range
          }
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
