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
    valueHandler.updateValue(field: 'threshold', value: value);
  }

  num? get threshold {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'threshold' && e.dimension == null)?.value,
    );
  }

  void updateRange(num value) {
    valueHandler.updateValue(field: 'range', value: value);
  }

  num? get range {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'range' && e.dimension == null)?.value,
    );
  }

  void updateAttack(num value) {
    valueHandler.updateValue(field: 'attack', value: value);
  }

  num? get attack {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'attack' && e.dimension == null)?.value,
    );
  }

  void updateHold(num value) {
    valueHandler.updateValue(field: 'hold', value: value);
  }

  num? get hold {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'hold' && e.dimension == null)?.value,
    );
  }

  void updateDecay(num value) {
    valueHandler.updateValue(field: 'decay', value: value);
  }

  num? get decay {
    return DeserializationUtil.numDeserializer.deserialize(
      allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'decay' && e.dimension == null)?.value,
    );
  }
}
