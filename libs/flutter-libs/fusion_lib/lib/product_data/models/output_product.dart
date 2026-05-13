import 'package:fusion_lib/fusion_lib.dart';

import '../product_data.dart';

enum OutputConnectionType {
  analogOutput("Analog Output"),
  aes67output("AES67 Output"),
  usbOutput("USB Output"),
  hdmi("HDMI");

  const OutputConnectionType(this.displayName);

  final String displayName;

  static OutputConnectionType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputConnectionType.analogOutput;
    return OutputConnectionType.values.firstWhereOrNull((OutputConnectionType e) => e.name.toLowerCase() == value.toLowerCase()) ??
        OutputConnectionType.analogOutput;
  }
}

class OutputProduct {
  final int id;
  final String name;
  final ProductAsset assets;
  final OutputConnectionType primaryConnection;
  final List<OutputConnectionType> supportedConnections;
  final bool isFusionCompatible;

  const OutputProduct({
    required this.id,
    required this.name,
    required this.assets,
    required this.primaryConnection,
    required this.supportedConnections,
    this.isFusionCompatible = true, // Mark it default to TRUE.
  });

  factory OutputProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    final supportedConnections = (specs['supported_connections'] as List<dynamic>?)?.map((e) => OutputConnectionType.fromString(e as String?)).toList() ?? [];

    return OutputProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'output'),
      primaryConnection: OutputConnectionType.fromString(specs['primary_connection'] as String?),
      supportedConnections: supportedConnections,
      isFusionCompatible: true, // Default to TRUE.
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assets': assets.toAssetList(),
    'specifications': {
      'primary_connection': primaryConnection.name,
      'supported_connections': supportedConnections.map((e) => e.name).toList(),
    },
    'is_fusion_compatible': isFusionCompatible,
  };
}
