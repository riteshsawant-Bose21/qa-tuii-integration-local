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

enum OutputDeviceType {
  media,
  amplifier;

  static OutputDeviceType fromString(String? value) {
    if (value == null || value.isEmpty) return OutputDeviceType.media;
    return OutputDeviceType.values.firstWhereOrNull((OutputDeviceType e) => e.name.toLowerCase() == value.toLowerCase()) ?? OutputDeviceType.media;
  }
}

class OutputProduct {
  final int outputId;
  final String name;
  final ProductAsset assets;
  final OutputDeviceType type;
  final List<OutputConnectionType> supportedConnections;
  final dynamic pagingType;

  const OutputProduct({
    required this.outputId,
    required this.name,
    required this.assets,
    required this.type,
    required this.supportedConnections,
    this.pagingType,
  });

  factory OutputProduct.fromJson(Map<String, dynamic> json) {
    final specs = json['specifications'] as Map<String, dynamic>? ?? {};

    final supportedConnections = (specs['supported_connections'] as List<dynamic>?)?.map((e) => OutputConnectionType.fromString(e as String)).toList() ?? [];

    return OutputProduct(
      outputId: (json['output_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      assets: ProductAsset.fromJsonList(json['assets'] as List<dynamic>?, productType: 'output'),
      type: OutputDeviceType.fromString(json['type']),
      supportedConnections: supportedConnections,
      pagingType: specs['paging_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'output_id': outputId,
    'name': name,
    'assets': assets.toAssetList(),
    'type': type.name,
    'specifications': {
      'supported_connections': supportedConnections.map((e) => e.apiName).toList(),
      'paging_type': pagingType,
    },
  };
}
