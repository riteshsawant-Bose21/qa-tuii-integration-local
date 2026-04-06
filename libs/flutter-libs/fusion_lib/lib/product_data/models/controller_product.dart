import 'product_asset.dart';

/// Controller product model
///
/// Represents a controller product from the product catalog API.
/// Field names follow the README specification.
class ControllerProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final List<String> additionalSensors;
  final List<String> applicableRegions;
  final String? controlType;
  final String? physicalSize;
  final String? shortDescription;
  final String? zoneControlCount;
  final List<String> skus;
  final bool isFusionCompatible;

  const ControllerProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.additionalSensors = const [],
    this.applicableRegions = const [],
    this.controlType,
    this.physicalSize,
    this.shortDescription,
    this.zoneControlCount,
    this.skus = const [],
    this.isFusionCompatible = false,
  });

  factory ControllerProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return ControllerProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'controller'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'System controller for comprehensive audio management',
      additionalSensors: (specs['additional_sensors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      applicableRegions: (specs['applicable_regions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      controlType: specs['control_type'] as String?,
      physicalSize: specs['physical_size'] as String?,
      shortDescription: specs['short_description'] as String?,
      zoneControlCount: specs['zone_control_count'] as String?,
      skus: (specs['skus'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'assets': assets.toAssetList(),
    'model_name': modelName,
    'model_family': modelFamily,
    'description': description,
    'specifications': {
      'additional_sensors': additionalSensors,
      'applicable_regions': applicableRegions,
      if (controlType != null) 'control_type': controlType,
      if (physicalSize != null) 'physical_size': physicalSize,
      if (shortDescription != null) 'short_description': shortDescription,
      if (zoneControlCount != null) 'zone_control_count': zoneControlCount,
      'skus': skus,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'ControllerProduct(productId: $productId, modelName: $modelName)';
}
