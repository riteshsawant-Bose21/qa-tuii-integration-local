import 'package:fusion_lib/fusion_lib.dart';

import '../product_data.dart';

class SourceProduct {
  final int productId;
  final String sourceId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String? description;
  final SourceType type;
  final SourceConnectionType primaryConnection;
  final List<SourceConnectionType> supportedConnections;
  final PagingSourceType? pagingType;
  final bool isFusionCompatible;

  const SourceProduct({
    required this.productId,
    required this.sourceId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.description,
    required this.type,
    required this.primaryConnection,
    required this.supportedConnections,
    this.pagingType,
    this.isFusionCompatible = true, // Mark it default to TRUE.
  });

  factory SourceProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    final supportedConnections = (specs['supported_connections'] as List<dynamic>?)?.map((e) => SourceConnectionType.fromString(e as String)).toList() ?? [];
    final pagingType = PagingSourceType.fromString(specs['paging_type']);

    return SourceProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      sourceId: json['source_id'] as String? ?? '',
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'source'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional audio source',
      type: SourceType.fromString(json['source_type']),
      primaryConnection: SourceConnectionType.fromString(specs['primary_connection']),
      supportedConnections: supportedConnections,
      pagingType: pagingType,
      isFusionCompatible: true, // Default to TRUE. // json['is_fusion_compatible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'source_id': sourceId,
    'assets': assets.toJson(),
    'model_name': modelName,
    'model_family': modelFamily,
    'description': description,
    'source_type': type.name,
    'specifications': {
      'primary_connection': primaryConnection.name,
      'supported_connections': supportedConnections.map((e) => e.name).toList(),
      if (pagingType != null) 'paging_type': pagingType!.name,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'SourceProduct(productId: $productId, modelName: $modelName)';
}
