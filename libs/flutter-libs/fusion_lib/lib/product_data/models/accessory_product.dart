import 'product_asset.dart';

/// Accessory product model
///
/// Represents an accessory product from the product catalog API.
/// Field names follow the README specification.
class AccessoryProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final String? dataSheetLink;
  final int? quantity;
  @Deprecated('Not available in the latest accessory response; kept for backward compatibility.')
  final String? shortDescription;
  @Deprecated('Not available in the latest accessory response; kept for backward compatibility.')
  final List<String> skus;
  @Deprecated('Not available in the latest accessory response; kept for backward compatibility.')
  final String? type;
  final bool isFusionCompatible;

  const AccessoryProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.dataSheetLink,
    this.quantity,
    this.shortDescription,
    this.skus = const [],
    this.type,
    this.isFusionCompatible = false,
  });

  factory AccessoryProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return AccessoryProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'accessory'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional audio accessory for enhanced system functionality',
      dataSheetLink: specs['data_sheet_link'] as String?,
      quantity: (specs['quantity'] as num?)?.toInt(),
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      type: specs['type'] as String?,
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
      if (dataSheetLink != null) 'data_sheet_link': dataSheetLink,
      if (quantity != null) 'quantity': quantity,
      if (shortDescription != null) 'short_description': shortDescription,
      'skus': skus,
      if (type != null) 'type': type,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'AccessoryProduct(productId: $productId, modelName: $modelName)';
}
