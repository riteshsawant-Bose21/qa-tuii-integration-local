import 'product_asset.dart';

/// Accessory product model
///
/// Represents an accessory product from the product catalog API.
/// Field names follow the README specification.
class AccessoryProduct {
  final int id;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final int? quantity;
  final String? shortDescription;
  final List<String> skus;
  final String? type;
  final bool isFusionCompatible;

  const AccessoryProduct({
    required this.id,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.quantity,
    this.shortDescription,
    this.skus = const [],
    this.type,
    this.isFusionCompatible = false,
  });

  factory AccessoryProduct.fromJson(Map<String, dynamic> json) {
    final specs = json;
    //['specifications'] as Map<String, dynamic>? ?? {};

    return AccessoryProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'accessory'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional audio accessory for enhanced system functionality',
      quantity: (specs['quantity'] as num?)?.toInt(),
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      type: specs['type'] as String?,
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assets': assets.toAssetList(),
    'model_name': modelName,
    'model_family': modelFamily,
    'description': description,
    'specifications': {
      if (quantity != null) 'quantity': quantity,
      if (shortDescription != null) 'short_description': shortDescription,
      'skus': skus,
      if (type != null) 'type': type,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'AccessoryProduct(id: $id, modelName: $modelName)';
}
