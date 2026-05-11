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

enum OutputDeviceType {
  media,
  amplifier;

  static OutputDeviceType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputDeviceType.media;
    return OutputDeviceType.values.firstWhereOrNull((OutputDeviceType e) => e.name.toLowerCase() == value.toLowerCase()) ?? OutputDeviceType.media;
  }
}

class OutputProduct {
  final int id;
  final String name;
  final ProductAsset assets;
  final OutputDeviceType type;
  final OutputConnectionType primaryConnection;
  final List<OutputConnectionType> supportedConnections;
  final bool isFusionCompatible;

  const OutputProduct({
    required this.id,
    required this.name,
    required this.assets,
    required this.type,
    required this.primaryConnection,
    required this.supportedConnections,
    this.isFusionCompatible = true, // Mark it default to TRUE.
  });

  factory OutputProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    final supportedConnections = (specs['supported_connections'] as List<dynamic>?)?.map((e) => OutputConnectionType.fromString(e as String)).toList() ?? [];

    final image = "${json['images'] ?? ''}";
    final List<dynamic> assetJson = [
      {
        "black": [image],
      },
    ];

    return OutputProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      assets: ProductAsset.fromJsonList(assetJson, productType: 'output'),
      type: OutputDeviceType.fromString(json['type']),
      primaryConnection: OutputConnectionType.fromString(specs['primary_connection']),
      supportedConnections: supportedConnections,
      isFusionCompatible: true, // Default to TRUE.
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assets': assets.toAssetList(),
    'type': type.name,
    'specifications': {
      'primary_connection': primaryConnection.name,
      'supported_connections': supportedConnections.map((e) => e.name).toList(),
    },
    'is_fusion_compatible': isFusionCompatible,
  };
}
