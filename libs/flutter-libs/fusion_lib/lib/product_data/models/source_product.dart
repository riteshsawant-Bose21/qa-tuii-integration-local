import 'package:fusion_lib/fusion_lib.dart';

import '../product_data.dart';

class SourceProduct {
  final int sourceId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String? description;
  final SourceConnectionType primaryConnection;
  final List<SourceConnectionType> supportedConnections;
  final PagingSourceType? pagingType;
  final bool isFusionCompatible;

  const SourceProduct({
    required this.sourceId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.description,
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
      sourceId: int.tryParse(json['source_id']?.toString() ?? '') ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'source'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'Professional audio source',
      primaryConnection: SourceConnectionType.fromString(specs['primary_connection']),
      supportedConnections: supportedConnections,
      pagingType: pagingType,
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'source_id': sourceId,
    'assets': assets.toJson(),
    'model_name': modelName,
    'model_family': modelFamily,
    'description': description,
    'specifications': {
      'primary_connection': primaryConnection.name,
      'supported_connections': supportedConnections.map((e) => e.name).toList(),
      if (pagingType != null) 'paging_type': pagingType!.name,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'SourceProduct(sourceId: $sourceId, modelName: $modelName)';
}
