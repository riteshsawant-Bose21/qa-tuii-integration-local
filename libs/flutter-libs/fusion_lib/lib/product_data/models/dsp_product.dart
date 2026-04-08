import 'product_asset.dart';
import 'product_port_data.dart';

/// DSP product model
///
/// Represents a DSP (Digital Signal Processor) product from the product catalog API.
/// Field names follow the README specification.
/// The numberOfInputsAndOutputs field accepts any schema structure.
class DspProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final dynamic acousticEchoCancellation;
  final dynamic certifications;
  final dynamic configurationSoftware;
  final dynamic currentDraw;
  final dynamic dimensions;
  final dynamic dspArchitecture;
  final dynamic firmware;
  final int? maxFusionControllers;
  final dynamic netWeight;
  final ProductPortData? numberOfInputsAndOutputs;
  final dynamic powerOutput;
  final dynamic productCodes;
  final dynamic safeOperatingTemperature;
  final dynamic supportedBoseProfessionalDanteEndpoints;
  final dynamic thermalOutput;
  final bool isFusionCompatible;

  const DspProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.acousticEchoCancellation,
    this.certifications,
    this.configurationSoftware,
    this.currentDraw,
    this.dimensions,
    this.dspArchitecture,
    this.firmware,
    this.maxFusionControllers,
    this.netWeight,
    this.numberOfInputsAndOutputs,
    this.powerOutput,
    this.productCodes,
    this.safeOperatingTemperature,
    this.supportedBoseProfessionalDanteEndpoints,
    this.thermalOutput,
    this.isFusionCompatible = false,
  });

  factory DspProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};
    final dynamic portDataJson = specs['number_of_inputs_and_outputs'];

    return DspProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'dsp'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      acousticEchoCancellation: specs['acoustic_echo_cancellation'],
      certifications: specs['certifications'],
      configurationSoftware: specs['configuration_software'],
      currentDraw: specs['current_draw'],
      dimensions: specs['dimensions'],
      dspArchitecture: specs['dsp_architecture'],
      firmware: specs['firmware'],
      maxFusionControllers: (specs['max_fusion_controllers'] as num?)?.toInt(),
      netWeight: specs['net_weight'],
      numberOfInputsAndOutputs: portDataJson is Map<String, dynamic> ? ProductPortData.fromMap(portDataJson) : null,
      powerOutput: specs['power_output'],
      productCodes: specs['product_codes'],
      safeOperatingTemperature: specs['safe_operating_temperature'],
      supportedBoseProfessionalDanteEndpoints: specs['supported_bose_professional_dante_endpoints'],
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
      if (acousticEchoCancellation != null) 'acoustic_echo_cancellation': acousticEchoCancellation,
      if (certifications != null) 'certifications': certifications,
      if (configurationSoftware != null) 'configuration_software': configurationSoftware,
      if (currentDraw != null) 'current_draw': currentDraw,
      if (dimensions != null) 'dimensions': dimensions,
      if (dspArchitecture != null) 'dsp_architecture': dspArchitecture,
      if (firmware != null) 'firmware': firmware,
      if (maxFusionControllers != null) 'max_fusion_controllers': maxFusionControllers,
      if (netWeight != null) 'net_weight': netWeight,
      if (numberOfInputsAndOutputs != null) 'number_of_inputs_and_outputs': numberOfInputsAndOutputs!.toMap(),
      if (powerOutput != null) 'power_output': powerOutput,
      if (productCodes != null) 'product_codes': productCodes,
      if (safeOperatingTemperature != null) 'safe_operating_temperature': safeOperatingTemperature,
      if (supportedBoseProfessionalDanteEndpoints != null) 'supported_bose_professional_dante_endpoints': supportedBoseProfessionalDanteEndpoints,
      if (thermalOutput != null) 'thermal_output': thermalOutput,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'DspProduct(productId: $productId, modelName: $modelName)';
}
