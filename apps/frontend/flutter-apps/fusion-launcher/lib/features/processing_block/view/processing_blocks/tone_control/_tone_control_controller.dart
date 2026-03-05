part of 'tone_control_block.dart';

class ToneController {
  final AlgorithmDataViewmodel valueHandler;
  ToneController(this.valueHandler);

  List<PropertySetting> get allProperties {
    return valueHandler.processingBlock.properties;
  }

  void bypassGlobally(bool value) {
    valueHandler.updateValue(field: 'bypass', value: value);
  }

  bool get isGloballyBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  }

  // Low gain controls
  num? get currentLowGain {
    final dynamic gainValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'low_gain' && e.dimension == null)?.value;
    if (gainValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(gainValue);
  }

  void updateLowGain(num value) {
    valueHandler.updateValue(field: 'low_gain', value: value);
  }

  bool get isLowBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'low_bypass' && e.dimension == null)?.value == true;
  }

  void updateLowBypass(bool value) {
    valueHandler.updateValue(field: 'low_bypass', value: value);
  }

  // Mid gain controls
  num? get currentMidGain {
    final dynamic gainValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'mid_gain' && e.dimension == null)?.value;
    if (gainValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(gainValue);
  }

  void updateMidGain(num value) {
    valueHandler.updateValue(field: 'mid_gain', value: value);
  }

  bool get isMidBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'mid_bypass' && e.dimension == null)?.value == true;
  }

  void updateMidBypass(bool value) {
    valueHandler.updateValue(field: 'mid_bypass', value: value);
  }

  // High gain controls
  num? get currentHighGain {
    final dynamic gainValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'high_gain' && e.dimension == null)?.value;
    if (gainValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(gainValue);
  }

  void updateHighGain(num value) {
    valueHandler.updateValue(field: 'high_gain', value: value);
  }

  bool get isHighBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'high_bypass' && e.dimension == null)?.value == true;
  }

  void updateHighBypass(bool value) {
    valueHandler.updateValue(field: 'high_bypass', value: value);
  }

  // Legacy methods (keeping for backward compatibility if needed)
  num? get toneValue => currentLowGain;

  void updateToneValue(num value) => updateLowGain(value);
}
