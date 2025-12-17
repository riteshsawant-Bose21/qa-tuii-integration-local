import 'product_asset.dart';

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

/// Represents input/output count configuration
class InputOutputCount {
  final int inputs;
  final int outputs;

  const InputOutputCount({
    required this.inputs,
    required this.outputs,
  });

  factory InputOutputCount.fromJson(Map<String, dynamic> json) {
    return InputOutputCount(
      inputs: (json['inputs'] as num?)?.toInt() ??
          (json['max_inputs'] as num?)?.toInt() ??
          0,
      outputs: (json['outputs'] as num?)?.toInt() ??
          (json['max_outputs'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'inputs': inputs,
        'outputs': outputs,
      };
}

/// Represents number of inputs and outputs for different connection types
class NumberOfInputsAndOutputs {
  final InputOutputCount? analog;
  final InputOutputCount? dante;
  final InputOutputCount? fusionConnect;

  const NumberOfInputsAndOutputs({
    this.analog,
    this.dante,
    this.fusionConnect,
  });

  factory NumberOfInputsAndOutputs.fromJson(Map<String, dynamic> json) {
    return NumberOfInputsAndOutputs(
      analog: json['analog'] != null
          ? InputOutputCount.fromJson(json['analog'] as Map<String, dynamic>)
          : null,
      dante: json['dante'] != null
          ? InputOutputCount.fromJson(json['dante'] as Map<String, dynamic>)
          : null,
      fusionConnect: json['fusion_connect'] != null
          ? InputOutputCount.fromJson(
              json['fusion_connect'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (analog != null) 'analog': analog!.toJson(),
        if (dante != null) 'dante': dante!.toJson(),
        if (fusionConnect != null) 'fusion_connect': fusionConnect!.toJson(),
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
      at: (json['at'] as List<dynamic>?)
              ?.map((e) =>
                  AmplifierMeasurementValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
class AmplifierProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final NumberOfInputsAndOutputs? numberOfInputsAndOutputs;
  final int numberOfLoudspeakerInputs;
  final Power? power;
  final Map<String, dynamic>? powerOutput;
  final String? shortDescription;
  final List<int> skus;

  const AmplifierProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.numberOfInputsAndOutputs,
    this.numberOfLoudspeakerInputs = 0,
    this.power,
    this.powerOutput,
    this.shortDescription,
    this.skus = const [],
  });

  factory AmplifierProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return AmplifierProduct(
      productId: (json['productid'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? '',
      numberOfInputsAndOutputs: specs['number_of_inputs_and_outputs'] != null
          ? NumberOfInputsAndOutputs.fromJson(
              specs['number_of_inputs_and_outputs'] as Map<String, dynamic>)
          : null,
      numberOfLoudspeakerInputs:
          (specs['number_of_loudspeaker_inputs'] as num?)?.toInt() ?? 0,
      power: specs['power'] != null
          ? Power.fromJson(specs['power'] as Map<String, dynamic>)
          : null,
      powerOutput: specs['power_output'] as Map<String, dynamic>?,
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'productid': productId,
        'assets': [assets.toJson()],
        'model_name': modelName,
        'model_family': modelFamily,
        'description': description,
        'specifications': {
          if (numberOfInputsAndOutputs != null)
            'number_of_inputs_and_outputs': numberOfInputsAndOutputs!.toJson(),
          'number_of_loudspeaker_inputs': numberOfLoudspeakerInputs,
          if (power != null) 'power': power!.toJson(),
          if (powerOutput != null) 'power_output': powerOutput,
          if (shortDescription != null) 'short_description': shortDescription,
          'skus': skus,
        },
      };

  @override
  String toString() =>
      'AmplifierProduct(productId: $productId, modelName: $modelName)';
}
