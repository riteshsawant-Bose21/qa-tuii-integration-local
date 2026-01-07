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
/// The numberOfInputsAndOutputs field accepts any schema structure.
class AmplifierProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final Map<String, dynamic>? numberOfInputsAndOutputs;
  final int numberOfLoudspeakerInputs;
  final Power? power;
  final Map<String, dynamic>? powerOutput;
  final String? shortDescription;
  final List<int> skus;
  final bool isFusionCompatible;

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
    this.isFusionCompatible = false,
  });

  factory AmplifierProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return AmplifierProduct(
      productId: (json['productid'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? '',
      numberOfInputsAndOutputs: specs['number_of_inputs_and_outputs'] as Map<String, dynamic>?,
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
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
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
            'number_of_inputs_and_outputs': numberOfInputsAndOutputs,
          'number_of_loudspeaker_inputs': numberOfLoudspeakerInputs,
          if (power != null) 'power': power!.toJson(),
          if (powerOutput != null) 'power_output': powerOutput,
          if (shortDescription != null) 'short_description': shortDescription,
          'skus': skus,
        },
        'is_fusion_compatible': isFusionCompatible,
      };

  @override
  String toString() =>
      'AmplifierProduct(productId: $productId, modelName: $modelName)';
}