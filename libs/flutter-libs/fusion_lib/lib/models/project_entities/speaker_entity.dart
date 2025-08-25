import 'dart:ui';

import 'hardware_component_entity.dart';
import 'location_entity.dart';
import 'processing_block_entity.dart';

enum OutputType { analogOutput, aes67output }

class Speaker extends HardwareComponent {
  double rotation;
  double gain;
  OutputType type;
  List<ProcessingBlockEntity> blocks;
  String? ipAddress; // Optional field for AES67 output type
  String speakerSKU;
  final List<int> portNumbers;
  final String? fusionDeviceId;

  Speaker({
    super.id,
    required super.locationEntity,
    required super.name,
    required super.pos,
    required this.speakerSKU,
    this.rotation = 0.0,
    required this.gain,
    required super.assetImagePath,
    List<ProcessingBlockEntity>? blocks,
    required this.type,
    this.ipAddress,
    List<int>? portNumbers,
    this.fusionDeviceId,
    required super.price,
    String? hardwareName,
  }) : blocks = blocks ?? <ProcessingBlockEntity>[],
       portNumbers = portNumbers ?? <int>[],
       super(hardwareName: hardwareName ?? name);

  @override
  Speaker copyWith({
    String? id,
    String? name,
    Offset? pos,
    double? rotation,
    double? gain,
    String? assetImagePath,
    List<ProcessingBlockEntity>? blocks,
    OutputType? type,
    String? listeningAreaId,
    LocationEntity? locationEntity,
    String? ipAddress,
    String? speakerSKU,
    List<int>? portNumbers,
    String? fusionDeviceId,
    double? price,
    String? hardwareName,
  }) {
    return Speaker(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      rotation: rotation ?? this.rotation,
      gain: gain ?? this.gain,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      blocks: blocks ?? this.blocks,
      type: type ?? this.type,
      locationEntity: locationEntity ?? this.locationEntity,
      ipAddress: ipAddress ?? this.ipAddress,
      speakerSKU: speakerSKU ?? this.speakerSKU,
      portNumbers: portNumbers ?? this.portNumbers,
      fusionDeviceId: fusionDeviceId ?? this.fusionDeviceId,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Speaker) return false;
    return id == other.id &&
        name == other.name &&
        pos == other.pos &&
        rotation == other.rotation &&
        gain == other.gain &&
        assetImagePath == other.assetImagePath &&
        blocks == other.blocks &&
        locationEntity == other.locationEntity &&
        ipAddress == other.ipAddress &&
        speakerSKU == other.speakerSKU &&
        type == other.type &&
        fusionDeviceId == other.fusionDeviceId &&
        portNumbers == other.portNumbers;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        pos.hashCode ^
        rotation.hashCode ^
        gain.hashCode ^
        assetImagePath.hashCode ^
        blocks.hashCode ^
        locationEntity.hashCode ^
        (ipAddress?.hashCode ?? 0) ^
        speakerSKU.hashCode ^
        type.hashCode ^
        fusionDeviceId.hashCode ^
        portNumbers.hashCode;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'rotation': rotation,
      'gain': gain,
      'assetImagePath': assetImagePath,
      'blocks': blocks.map((ProcessingBlockEntity block) => block.toJson()).toList(),
      'componentType': 'speaker',
      'type': type.name,
      'locationEntity': locationEntity.toJson(),
      'ipAddress': ipAddress,
      'speakerSKU': speakerSKU,
      'portNumbers': portNumbers,
      'fusionDeviceId': fusionDeviceId,
      'price': price,
      'hardwareName': hardwareName,
    };
  }

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String?,
      name: json['name'] as String,
      pos: Offset(json['pos']['dx'] as double, json['pos']['dy'] as double),
      rotation: (json['rotation'] as num).toDouble(),
      gain: (json['gain'] as num).toDouble(),
      assetImagePath: json['assetImagePath'] as String,
      blocks: (json['blocks'] as List<dynamic>?)?.map((dynamic e) => ProcessingBlockEntity.fromJson(e as Map<String, dynamic>)).toList(),
      type: OutputType.values.firstWhere((OutputType e) => e.name == json['type'], orElse: () => OutputType.analogOutput),
      locationEntity: LocationEntity.fromJson(json['locationEntity'] as Map<String, dynamic>),
      ipAddress: json['ipAddress'] as String?,
      speakerSKU: json['speakerSKU'] as String,
      portNumbers: (json['portNumbers'] as List<dynamic>?)?.map((dynamic e) => e as int).toList() ?? <int>[],
      fusionDeviceId: json['fusionDeviceId'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? '',
    );
  }
}
