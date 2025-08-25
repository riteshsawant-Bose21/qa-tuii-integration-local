import 'dart:ui';

import 'hardware_component_entity.dart';
import 'location_entity.dart';
import 'processing_block_entity.dart';

enum SourceType { analogInput, aes67input, bluetooth }

class Source extends HardwareComponent {
  /// Type of the source
  final SourceType type;
  List<ProcessingBlockEntity> blocks;
  String? ipAddress; //for AES67 sources
  final List<int> portNumbers;
  final String? fusionDeviceId;
  final String sku;

  /// Constructor for SourceEntity
  Source({
    super.id,
    required super.locationEntity,
    required super.name,
    super.pos,
    required this.type,
    required super.assetImagePath,
    List<ProcessingBlockEntity>? blocks,
    this.ipAddress,
    List<int>? portNumbers,
    this.fusionDeviceId,
    required this.sku,
    required super.price,
    String? hardwareName,
  }) : blocks = blocks ?? <ProcessingBlockEntity>[],
       portNumbers = portNumbers ?? <int>[],
       super(hardwareName: hardwareName ?? name);

  @override
  Source copyWith({
    String? id,
    String? name,
    Offset? pos,
    SourceType? type,
    String? assetImagePath,
    List<ProcessingBlockEntity>? blocks,
    LocationEntity? locationEntity,
    String? ipAddress,
    List<int>? portNumbers,
    String? fusionDeviceId,
    String? sku,
    double? price,
    String? hardwareName,
  }) {
    return Source(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      type: type ?? this.type,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      blocks: blocks ?? this.blocks,
      locationEntity: locationEntity ?? this.locationEntity,
      ipAddress: ipAddress ?? this.ipAddress,
      portNumbers: portNumbers ?? this.portNumbers,
      fusionDeviceId: fusionDeviceId ?? this.fusionDeviceId,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
    );
  }

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: Offset(json['pos']['dx'] as double, json['pos']['dy'] as double),
      type: SourceType.values.firstWhere(
        (SourceType e) => e.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => throw FormatException('Unknown SourceType in JSON: ${json['type']}'),
      ),
      assetImagePath: json['assetImagePath'] as String,
      blocks: (json['blocks'] as List<dynamic>?)?.map((dynamic e) => ProcessingBlockEntity.fromJson(e as Map<String, dynamic>)).toList(),
      locationEntity: LocationEntity.fromJson(json['locationEntity'] as Map<String, dynamic>),
      ipAddress: json['ipAddress'] as String?,
      portNumbers: (json['portNumbers'] as List<dynamic>?)?.map((dynamic e) => e as int).toList() ?? <int>[],
      fusionDeviceId: json["fusionDeviceId"] as String?,
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'type': type.name,
      'assetImagePath': assetImagePath,
      'blocks': blocks.map((ProcessingBlockEntity e) => e.toJson()).toList(),
      'componentType': 'source',
      'locationEntity': locationEntity.toJson(),
      'ipAddress': ipAddress,
      'portNumbers': portNumbers,
      'fusionDeviceId': fusionDeviceId,
      'sku': sku,
      'price': price,
      'hardwareName': hardwareName,
    };
  }
}
