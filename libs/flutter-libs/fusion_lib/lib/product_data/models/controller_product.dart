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
  final List<dynamic> additionalSensors;
  final dynamic controlType;
  final dynamic zoneControlCount;
  final bool isFusionCompatible;

  const ControllerProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.additionalSensors = const <dynamic>[],
    this.controlType,
    this.zoneControlCount,
    this.isFusionCompatible = false,
  });

  factory ControllerProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return ControllerProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'controller'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      additionalSensors: (specs['additional_sensors'] as List<dynamic>?) ?? const <dynamic>[],
      controlType: specs['control_type'],
      zoneControlCount: specs['zone_control_count'],
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'assets': assets.toAssetList(),
    'model_name': modelName,
    'model_family': modelFamily,
    'specifications': {
      'additional_sensors': additionalSensors,
      if (controlType != null) 'control_type': controlType,
      if (zoneControlCount != null) 'zone_control_count': zoneControlCount,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'ControllerProduct(productId: $productId, modelName: $modelName)';
}
