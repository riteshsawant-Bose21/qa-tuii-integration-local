import 'package:fusion_lib/fusion_lib.dart';

import '../product_data.dart';

enum OutputConnectionType {
  analogOutput("Analog Output"),
  aes67Output("AES67 Output"),
  usbOutput("USB Output"),
  hdmi("HDMI");

  const OutputConnectionType(this.displayName);

  final String displayName;

  String get apiName {
    switch (this) {
      case OutputConnectionType.usbOutput:
        return 'usb';
      default:
        return name;
    }
  }

  static OutputConnectionType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputConnectionType.analogOutput;
    final normalized = switch (value.toLowerCase()) {
      'usb' => 'usboutput',
      'aes67output' => 'aes67output',
      _ => value.toLowerCase(),
    };
    return OutputConnectionType.values.firstWhereOrNull((OutputConnectionType e) => e.name.toLowerCase() == normalized) ?? OutputConnectionType.analogOutput;
  }
}

class OutputProduct {
  final int outputId;
  final String name;
  final ProductAsset assets;
  final OutputConnectionType primaryConnection;
  final List<OutputConnectionType> supportedConnections;
  final dynamic pagingType;

  const OutputProduct({
    required this.outputId,
    required this.name,
    required this.assets,
    required this.primaryConnection,
    required this.supportedConnections,
    this.pagingType,
  });

  factory OutputProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    final supportedConnections = (specs['supported_connections'] as List<dynamic>?)?.map((e) => OutputConnectionType.fromString(e as String?)).toList() ?? [];

    return OutputProduct(
      outputId: (json['output_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'output'),
      primaryConnection: OutputConnectionType.fromString(specs['primary_connection'] as String?),
      supportedConnections: supportedConnections,
      pagingType: specs['paging_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'output_id': outputId,
    'name': name,
    'assets': assets.toAssetList(),
    'specifications': {
      'supported_connections': supportedConnections.map((e) => e.apiName).toList(),
      'paging_type': pagingType,
    },
  };
}
