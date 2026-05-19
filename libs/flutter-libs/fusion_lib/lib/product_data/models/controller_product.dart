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
  final dynamic applicableRegions;
  final dynamic controlType;
  final String? dataSheetLink;
  final dynamic dimensions;
  final dynamic physicalSize;
  final dynamic zoneControlCount;
  final bool isFusionCompatible;

  const ControllerProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.additionalSensors = const <dynamic>[],
    this.applicableRegions,
    this.controlType,
    this.dataSheetLink,
    this.dimensions,
    this.physicalSize,
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
      applicableRegions: specs['applicable_regions'],
      controlType: specs['control_type'],
      dataSheetLink: specs['data_sheet_link'] as String?,
      dimensions: specs['dimensions'],
      physicalSize: specs['physical_size'],
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
      if (applicableRegions != null) 'applicable_regions': applicableRegions,
      if (controlType != null) 'control_type': controlType,
      if (dataSheetLink != null) 'data_sheet_link': dataSheetLink,
      if (dimensions != null) 'dimensions': dimensions,
      if (physicalSize != null) 'physical_size': physicalSize,
      if (zoneControlCount != null) 'zone_control_count': zoneControlCount,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'ControllerProduct(productId: $productId, modelName: $modelName)';
}
