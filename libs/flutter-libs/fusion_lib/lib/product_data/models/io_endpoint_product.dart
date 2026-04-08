import 'product_asset.dart';
import 'product_port_data.dart';

/// I/O Endpoint product model
///
/// Represents an I/O endpoint product from the product catalog API.
/// Field names follow the README specification.
class IoEndpointProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final ProductPortData? numberOfInputsAndOutputs;
  final bool network;
  final bool isFusionCompatible;

  const IoEndpointProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    this.numberOfInputsAndOutputs,
    this.network = false,
    this.isFusionCompatible = false,
  });

  factory IoEndpointProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};
    final dynamic ioPortsJson = specs['number_of_inputs_and_outputs'];

    return IoEndpointProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'io_endpoint'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      numberOfInputsAndOutputs: ioPortsJson is Map<String, dynamic> ? ProductPortData.fromMap(ioPortsJson) : null,
      network: specs['network'] as bool? ?? false,
      isFusionCompatible: json['is_fusion_compatible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'assets': assets.toAssetList(),
    'model_name': modelName,
    'model_family': modelFamily,
    'specifications': {
      if (numberOfInputsAndOutputs != null) 'number_of_inputs_and_outputs': numberOfInputsAndOutputs!.toMap(),
      'network': network,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'IoEndpointProduct(productId: $productId, modelName: $modelName)';
}
