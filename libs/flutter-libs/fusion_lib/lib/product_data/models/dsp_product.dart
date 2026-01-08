import 'product_asset.dart';

/// Represents GPIO logic ports configuration
class GpioLogicPorts {
  final int inputs;
  final int outputs;

  const GpioLogicPorts({
    required this.inputs,
    required this.outputs,
  });

  factory GpioLogicPorts.fromJson(Map<String, dynamic> json) {
    return GpioLogicPorts(
      inputs: (json['inputs'] as num?)?.toInt() ?? 0,
      outputs: (json['outputs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'inputs': inputs,
        'outputs': outputs,
      };
}

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
  final String description;
  final GpioLogicPorts? gpioLogicPorts;
  final int maxNumberOfAnalogControl;
  final int maxNumberOfDigitalControl;
  final Map<String, dynamic>? numberOfInputsAndOutputs;
  final String? shortDescription;
  final List<int> skus;
  final bool isFusionCompatible;

  const DspProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.gpioLogicPorts,
    this.maxNumberOfAnalogControl = 0,
    this.maxNumberOfDigitalControl = 0,
    this.numberOfInputsAndOutputs,
    this.shortDescription,
    this.skus = const [],
    this.isFusionCompatible = false,
  });

  factory DspProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return DspProduct(
      productId: (json['productid'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'dsp'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Digital Signal Processor for advanced audio processing and optimization',
      gpioLogicPorts: specs['gpio_logic_ports'] != null
          ? GpioLogicPorts.fromJson(
              specs['gpio_logic_ports'] as Map<String, dynamic>)
          : null,
      maxNumberOfAnalogControl:
          (specs['max_number_of_analog_control'] as num?)?.toInt() ?? 0,
      maxNumberOfDigitalControl:
          (specs['max_number_of_digital_control'] as num?)?.toInt() ?? 0,
      numberOfInputsAndOutputs: specs['number_of_inputs_and_outputs'] as Map<String, dynamic>?,
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'productid': productId,
        'assets': assets.toAssetList(),
        'model_name': modelName,
        'model_family': modelFamily,
        'description': description,
        'specifications': {
          if (gpioLogicPorts != null)
            'gpio_logic_ports': gpioLogicPorts!.toJson(),
          'max_number_of_analog_control': maxNumberOfAnalogControl,
          'max_number_of_digital_control': maxNumberOfDigitalControl,
          if (numberOfInputsAndOutputs != null)
            'number_of_inputs_and_outputs': numberOfInputsAndOutputs,
          if (shortDescription != null) 'short_description': shortDescription,
          'skus': skus,
        },
        'is_fusion_compatible': isFusionCompatible,
      };

  @override
  String toString() =>
      'DspProduct(productId: $productId, modelName: $modelName)';
}