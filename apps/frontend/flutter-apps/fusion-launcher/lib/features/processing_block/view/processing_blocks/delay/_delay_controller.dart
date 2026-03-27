part of 'delay_block.dart';

enum _UnitsType {
  milliseconds('milliseconds', "Milliseconds", "ms"),
  seconds("seconds", "Seconds", 'sec'),
  samples("samples", "Samples", "sample"),
  meter("meter", "Meter", "m"),
  feet("feet", "Feet", "ft"),
  inches("inches", "Inches", "in");

  const _UnitsType(this.value, this.label, this.shortLabel);
  final String value;
  final String label;
  final String shortLabel;
}

class DelayController {
  final AlgorithmDataViewmodel valueHandler;
  DelayController(this.valueHandler);

  List<PropertySetting> get allProperties {
    return valueHandler.processingBlock.properties;
  }

  void bypassGlobally(bool value) {
    valueHandler.updateValue(field: 'bypass', value: value);
  }

  /// Updates the band type (e.g., milliseconds or seconds) in the processing block's properties.
  void updateUnits(String value) {
    valueHandler.updateValue(field: 'unit', value: value);
  }

  void updateDelay(num value) {
    valueHandler.updateValue(field: 'max_delay', value: value);
  }

  bool get isGloballyBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  }

  _UnitsType? get currentUnits {
    final String? unitValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'unit' && e.dimension == null)?.value as String?;
    if (unitValue == null) {
      return null;
    }
    return _UnitsType.values.firstWhereOrNull((_UnitsType e) => e.value == unitValue);
  }

  num? get currentDelay {
    final dynamic delayValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'max_delay' && e.dimension == null)?.value;
    if (delayValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(delayValue);
  }
}
