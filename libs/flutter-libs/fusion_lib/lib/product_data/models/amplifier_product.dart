import 'product_asset.dart';
import 'product_port_data.dart';

/// Represents a measurement value with key, unit, and value
class AmplifierMeasurementValue {
  final String key;
  final String unit;
  final double value;

  const AmplifierMeasurementValue({
    required this.key,
    required this.unit,
    required this.value,
  });

  factory AmplifierMeasurementValue.fromJson(Map<String, dynamic> json) {
    return AmplifierMeasurementValue(
      key: json['key'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'unit': unit,
    'value': value,
  };
}

/// Represents power specification with multiple measurements
class Power {
  final List<AmplifierMeasurementValue> at;
  final String unit;

  const Power({
    required this.at,
    this.unit = 'Watts',
  });

  factory Power.fromJson(Map<String, dynamic> json) {
    return Power(
      at: (json['at'] as List<dynamic>?)?.map((e) => AmplifierMeasurementValue.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      unit: json['unit'] as String? ?? 'Watts',
    );
  }

  Map<String, dynamic> toJson() => {
    'at': at.map((e) => e.toJson()).toList(),
    'unit': unit,
  };
}

/// Amplifier product model
///
/// Represents an amplifier product from the product catalog API.
/// Field names follow the README specification.
/// The numberOfInputsAndOutputs field accepts any schema structure.
class AmplifierProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final dynamic certifications;
  final dynamic colors;
  final dynamic currentDraw;
  final dynamic dimensions;
  final dynamic firmware;
  final dynamic frontPanelImage;
  final dynamic netWeight;
  final ProductPortData? numberOfInputsAndOutputs;
  final int? numberOfLoudspeakerOutputs;
  final Map<String, dynamic>? powerOutput;
  final dynamic productCodes;
  final dynamic rackHeight;
  final dynamic rearPanelImage;
  final dynamic safeOperatingTemperature;
  final dynamic thermalOutput;
  final bool isFusionCompatible;

  const AmplifierProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.certifications,
    this.colors,
    this.currentDraw,
    this.dimensions,
    this.firmware,
    this.frontPanelImage,
    this.netWeight,
    this.numberOfInputsAndOutputs,
    this.numberOfLoudspeakerOutputs,
    this.powerOutput,
    this.productCodes,
    this.rackHeight,
    this.rearPanelImage,
    this.safeOperatingTemperature,
    this.thermalOutput,
    this.isFusionCompatible = false,
  });

  factory AmplifierProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};
    final dynamic portDataJson = specs['number_of_inputs_and_outputs'];
    final dynamic powerOutputJson = specs['power_output'];

    return AmplifierProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'amplifier'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      certifications: specs['certifications'],
      colors: specs['colors'],
      currentDraw: specs['current_draw'],
      dimensions: specs['dimensions'],
      firmware: specs['firmware'],
      frontPanelImage: specs['front_panel_image'],
      netWeight: specs['net_weight'],
      numberOfInputsAndOutputs: portDataJson is Map<String, dynamic> ? ProductPortData.fromMap(portDataJson) : null,
      numberOfLoudspeakerOutputs: (specs['number_of_loudspeaker_outputs'] as num?)?.toInt(),
      powerOutput: powerOutputJson is Map<String, dynamic> ? powerOutputJson : null,
      productCodes: specs['product_codes'],
      rackHeight: specs['rack_height'],
      rearPanelImage: specs['rear_panel_image'],
      safeOperatingTemperature: specs['safe_operating_temperature'],
      thermalOutput: specs['thermal_output'],
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'assets': assets.toAssetList(),
    'model_name': modelName,
    'model_family': modelFamily,
    'specifications': {
      if (certifications != null) 'certifications': certifications,
      if (colors != null) 'colors': colors,
      if (currentDraw != null) 'current_draw': currentDraw,
      if (dimensions != null) 'dimensions': dimensions,
      if (firmware != null) 'firmware': firmware,
      if (frontPanelImage != null) 'front_panel_image': frontPanelImage,
      if (netWeight != null) 'net_weight': netWeight,
      if (numberOfInputsAndOutputs != null) 'number_of_inputs_and_outputs': numberOfInputsAndOutputs!.toMap(),
      if (numberOfLoudspeakerOutputs != null) 'number_of_loudspeaker_outputs': numberOfLoudspeakerOutputs,
      if (powerOutput != null) 'power_output': powerOutput,
      if (productCodes != null) 'product_codes': productCodes,
      if (rackHeight != null) 'rack_height': rackHeight,
      if (rearPanelImage != null) 'rear_panel_image': rearPanelImage,
      if (safeOperatingTemperature != null) 'safe_operating_temperature': safeOperatingTemperature,
      if (thermalOutput != null) 'thermal_output': thermalOutput,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'AmplifierProduct(productId: $productId, modelName: $modelName)';
}
