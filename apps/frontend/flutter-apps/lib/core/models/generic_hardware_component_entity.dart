import 'dart:ui';

import 'hardware_component_entity.dart';
import 'location_entity.dart';

enum GenericHardwareComponentType { controller, rack, other }

class GenericHardwareComponent extends HardwareComponent {
  GenericHardwareComponentType type;
  final String sku;

  GenericHardwareComponent({
    super.id,
    required super.locationEntity,
    required super.name,
    required Offset super.pos,
    required this.type,
    required super.assetImagePath,
    required super.price,
    String? sku,
    String? hardwareName,
  }) : sku = sku ?? name,
       super(
         hardwareName: hardwareName ?? name,
       );

  @override
  GenericHardwareComponent copyWith({
    String? id,
    String? name,
    Offset? pos,
    GenericHardwareComponentType? type,
    String? assetImagePath,
    LocationEntity? locationEntity,
    double? price,
    String? hardwareName,
    String? sku,
  }) {
    return GenericHardwareComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      type: type ?? this.type,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      sku: sku ?? this.sku,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'type': type.name,
      'assetImagePath': assetImagePath,
      'componentType': 'generic',
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'sku': sku,
    };
  }

  factory GenericHardwareComponent.fromJson(Map<String, dynamic> json) {
    final String rawType = (json['type'] as String? ?? '').toLowerCase();

    final GenericHardwareComponentType productType = GenericHardwareComponentType.values.firstWhere(
      (GenericHardwareComponentType e) => e.name.toLowerCase() == rawType,
      orElse: () {
        throw FormatException(
          'Unknown CanvasProductType "$rawType" in JSON: $json',
        );
      },
    );

    final Map<String, dynamic> posMap = json['pos'] as Map<String, dynamic>? ?? (throw FormatException('Missing "pos" in CanvasProduct JSON: $json'));

    final double dx = (posMap['dx'] as num?)?.toDouble() ?? (throw FormatException('Invalid pos.dx in CanvasProduct JSON: $json'));
    final double dy = (posMap['dy'] as num?)?.toDouble() ?? (throw FormatException('Invalid pos.dy in CanvasProduct JSON: $json'));

    return GenericHardwareComponent(
      id: json['id'] as String?,
      name: json['name'] as String? ?? (throw FormatException('Missing "name" in CanvasProduct JSON: $json')),
      pos: Offset(dx, dy),
      type: productType,
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationEntity.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'],
      sku: json['sku'] as String? ?? '',
    );
  }
}
