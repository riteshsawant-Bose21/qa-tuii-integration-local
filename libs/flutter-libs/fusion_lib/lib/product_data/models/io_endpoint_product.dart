import 'product_asset.dart';

/// Represents I/O endpoint port configuration
class IoPort {
  final int quantity;
  final String type;

  const IoPort({
    required this.quantity,
    required this.type,
  });

  factory IoPort.fromJson(Map<String, dynamic> json) {
    return IoPort(
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'type': type,
      };
}

/// I/O Endpoint product model
///
/// Represents an I/O endpoint product from the product catalog API.
/// Field names follow the README specification.
class IoEndpointProduct {
  final int productId;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final IoPort? inputs;
  final bool network;
  final IoPort? outputs;
  final String? shortDescription;
  final List<int> skus;

  const IoEndpointProduct({
    required this.productId,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    this.inputs,
    this.network = false,
    this.outputs,
    this.shortDescription,
    this.skus = const [],
  });

  factory IoEndpointProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return IoEndpointProduct(
      productId: (json['productid'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? '',
      inputs: specs['inputs'] != null
          ? IoPort.fromJson(specs['inputs'] as Map<String, dynamic>)
          : null,
      network: specs['network'] as bool? ?? false,
      outputs: specs['outputs'] != null
          ? IoPort.fromJson(specs['outputs'] as Map<String, dynamic>)
          : null,
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
          if (inputs != null) 'inputs': inputs!.toJson(),
          'network': network,
          if (outputs != null) 'outputs': outputs!.toJson(),
          if (shortDescription != null) 'short_description': shortDescription,
          'skus': skus,
        },
      };

  @override
  String toString() =>
      'IoEndpointProduct(productId: $productId, modelName: $modelName)';
}
