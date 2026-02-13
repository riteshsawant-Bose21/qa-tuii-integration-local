part of 'agc_block.dart';

class AgcController {
  final AlgorithmDataViewmodel valueHandler;

  AgcController(this.valueHandler);

  List<PropertySetting> get allProperties => valueHandler.processingBlock.properties;

  bool get isGloballyBypassed => allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  void bypassGlobally(bool value) => valueHandler.updateValue(field: 'bypass', value: value);

  void updateThreshold(num value) => valueHandler.updateValue(field: 'threshold', value: value);
  double get currentThreshold {
    final dynamic thresholdValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'threshold' && e.dimension == null)?.value;
    if (thresholdValue == null) return 0.0;
    return DeserializationUtil.numDeserializer.deserialize(thresholdValue)?.toDouble() ?? 0.0;
  }

  void updateReduction(num value) => valueHandler.updateValue(field: 'reduction', value: value);
  double get currentReduction {
    final dynamic reductionValue = allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'reduction' && e.dimension == null)?.value;
    if (reductionValue == null) return 0.0;
    return DeserializationUtil.numDeserializer.deserialize(reductionValue)?.toDouble() ?? 0.0;
  }
}
