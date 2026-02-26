part of 'gain_block.dart';

class GainController {
  GainController(this.valueHandler);
  final AlgorithmDataViewmodel valueHandler;

  List<PropertySetting> get allProperties {
    return valueHandler.processingBlock.properties;
  }

  void bypassGlobally(bool value) {
    valueHandler.updateValue(field: 'bypass', value: value);
  }

  bool get isGloballyBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  }

  /// current v peak threshold value
  num? get currentGainSliderValue {
    final dynamic thresholdValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'gain' && e.dimension == null)?.value;
    if (thresholdValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(thresholdValue);
  }

  void updateGainSliderValue(num value) {
    valueHandler.updateValue(field: 'gain', value: value);
  }

  num? get currentGainValue {
    final dynamic gainValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'gain' && e.dimension == null)?.value;
    if (gainValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(gainValue);
  }

  void updateGainValue(num value) {
    valueHandler.updateValue(field: 'gain', value: value);
  }

  /// current gain mute value
  bool get isGainMuted {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'mute' && e.dimension == null)?.value == true;
  }

  void toggleGainMute(bool value) {
    print("Toggling gain mute to: $value");
    valueHandler.updateValue(field: 'mute', value: value);
  }
}
