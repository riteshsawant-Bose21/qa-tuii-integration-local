import 'product_asset.dart';
import 'product_port_data.dart';

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

/// Represents ports grouped by input/output for a specific connection type
class ConnectionTypePorts {
  final int inputs;
  final int outputs;

  const ConnectionTypePorts({
    this.inputs = 0,
    this.outputs = 0,
  });

  factory ConnectionTypePorts.fromJson(Map<String, dynamic> json) {
    return ConnectionTypePorts(
      inputs: (json['inputs'] as num?)?.toInt() ?? 0,
      outputs: (json['outputs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'inputs': inputs,
    'outputs': outputs,
  };
}

/// I/O Endpoint product model
///
/// Represents an I/O endpoint product from the product catalog API.
/// Field names follow the README specification.
class IoEndpointProduct {
  final int id;
  final ProductAsset assets;
  final String modelName;
  final String modelFamily;
  final String description;
  final ProductPortData numberOfInputsAndOutputs;
  final bool network;
  final String? shortDescription;
  final List<int> skus;
  final bool isFusionCompatible;

  const IoEndpointProduct({
    required this.id,
    required this.assets,
    required this.modelName,
    required this.modelFamily,
    required this.description,
    required this.numberOfInputsAndOutputs,
    this.network = false,
    this.shortDescription,
    this.skus = const [],
    this.isFusionCompatible = false,
  });

  factory IoEndpointProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    return IoEndpointProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'io_endpoint'),
      modelName: json['model_name'] as String? ?? '',
      modelFamily: json['model_family'] as String? ?? '',
      description: json['description'] as String? ?? 'I/O Endpoint - Professional audio interface for seamless connectivity',
      numberOfInputsAndOutputs: specs['number_of_inputs_and_outputs'] != null
          ? ProductPortData.fromMap(specs['number_of_inputs_and_outputs'] as Map<String, dynamic>)
          : ProductPortData(),
      network: specs['network'] as bool? ?? false,
      shortDescription: specs['short_description'] as String?,
      skus: (specs['skus'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
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
      'numberOfInputsAndOutputs': numberOfInputsAndOutputs.toJson(),
      'network': network,
      if (shortDescription != null) 'short_description': shortDescription,
      'skus': skus,
    },
    'is_fusion_compatible': isFusionCompatible,
  };

  @override
  String toString() => 'IoEndpointProduct(id: $id, modelName: $modelName)';
}
