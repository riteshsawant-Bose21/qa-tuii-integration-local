part of 'limiter_block.dart';

class LimiterController {
  final AlgorithmDataViewmodel valueHandler;
  LimiterController(this.valueHandler);

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
  num? get currentThreshold {
    final dynamic thresholdValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'peak_threshold' && e.dimension == null)?.value;
    if (thresholdValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(thresholdValue);
  }

  void updateThreshold(num value) {
    valueHandler.updateValue(field: 'peak_threshold', value: value);
  }

  /// current release time value

  num? get currentRMSReleaseTime {
    final dynamic releaseTimeValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'rms_release' && e.dimension == null)?.value;
    if (releaseTimeValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(releaseTimeValue);
  }

  void updateRMSReleaseTime(num value) {
    valueHandler.updateValue(field: 'rms_release', value: value);
  }

  /// current attack time value
  num? get currentRMSAttackTime {
    final dynamic attackTimeValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'rms_attack' && e.dimension == null)?.value;
    if (attackTimeValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(attackTimeValue);
  }

  void updateRMSAttackTime(num value) {
    valueHandler.updateValue(field: 'rms_attack', value: value);
  }

  /// current release threshold value
  num? get currentRMSThreshold {
    final dynamic releaseThresholdValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'rms_threshold' && e.dimension == null)?.value;
    if (releaseThresholdValue == null) {
      return null;
    }
    return DeserializationUtil.numDeserializer.deserialize(releaseThresholdValue);
  }

  void updateRMSThreshold(num value) {
    valueHandler.updateValue(field: 'rms_threshold', value: value);
  }
}
