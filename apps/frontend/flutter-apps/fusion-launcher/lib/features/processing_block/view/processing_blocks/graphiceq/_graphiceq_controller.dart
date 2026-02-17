part of 'graphiceq_block.dart';

class GraphicEqController {
  static const int totalGraphicEqBands = 31;

  static List<num> get graphicEqFrequencies => <num>[
    20,
    25,
    31.5,
    40,
    50,
    63,
    80,
    100,
    125,
    160,
    200,
    250,
    315,
    400,
    500,
    630,
    800,
    1000,
    1250,
    1600,
    2000,
    2500,
    3150,
    4000,
    5000,
    6300,
    8000,
    10000,
    12500,
    16000,
    20000,
  ];

  final AlgorithmDataViewmodel valueHandler;

  GraphicEqController(this.valueHandler);

  List<PropertySetting> get allProperties => valueHandler.processingBlock.properties;

  bool get isGloballyBypassed => allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  void bypassGlobally(bool value) => valueHandler.updateValue(field: 'bypass', value: value);

  double getBandValue(int bandIndex) {
    final String fieldName = graphicEqFrequencies[bandIndex].toString();
    final dynamic value = allProperties.firstWhereOrNull((PropertySetting e) => e.name == fieldName && e.dimension == null)?.value;
    if (value == null) return 0.0;
    return DeserializationUtil.numDeserializer.deserialize(value)?.toDouble() ?? 0.0;
  }

  void updateBandValue(int bandIndex, num newValue) {
    final String fieldName = graphicEqFrequencies[bandIndex].toString();
    valueHandler.updateValue(field: fieldName, value: newValue);
  }

  void flattenAll() {
    for (num freq in graphicEqFrequencies) {
      final String fieldName = freq.toString();
      valueHandler.updateValue(field: fieldName, value: 0.0);
    }
  }
}
