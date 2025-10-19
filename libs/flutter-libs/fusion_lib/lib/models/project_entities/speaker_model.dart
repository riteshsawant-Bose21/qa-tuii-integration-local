import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

enum OutputType { analogOutput, aes67output }

class Speaker extends HardwareComponent {
  double rotation;
  double gain;
  OutputType type;
  String? ipAddress; // Optional field for AES67 output type
  String speakerSKU;
  final double pitch;
  final double roll;
  final double yaw;

  Speaker({
    String? id,
    required super.locationEntity,
    required super.name,
    required super.pos,
    super.wiringPos,
    required this.speakerSKU,
    this.rotation = 0.0,
    required this.gain,
    super.zAxis,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.yaw = 0.0,
    required super.assetImagePath,
    required this.type,
    this.ipAddress,
    List<int>? portNumbers,
    required super.price,
    super.lockListeningArea,
    String? hardwareName,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
  }) : super(
         hardwareName: hardwareName ?? name,
         id: id ?? "SPEAKER${FusionUtils.shortStringUUID()}",
       );

  @override
  Speaker copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? rotation,
    double? gain,
    double? zAxis,
    String? assetImagePath,
    OutputType? type,
    String? listeningAreaId,
    LocationModel? locationEntity,
    String? ipAddress,
    String? speakerSKU,
    double? price,
    String? hardwareName,
    double? pitch,
    double? roll,
    double? yaw,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return Speaker(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      rotation: rotation ?? this.rotation,
      gain: gain ?? this.gain,
      zAxis: zAxis ?? this.zAxis,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      type: type ?? this.type,
      locationEntity: locationEntity ?? this.locationEntity,
      ipAddress: ipAddress ?? this.ipAddress,
      speakerSKU: speakerSKU ?? this.speakerSKU,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      yaw: yaw ?? this.yaw,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
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
        locationEntity == other.locationEntity &&
        ipAddress == other.ipAddress &&
        speakerSKU == other.speakerSKU &&
        type == other.type &&
        zAxis == other.zAxis;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        pos.hashCode ^
        rotation.hashCode ^
        gain.hashCode ^
        assetImagePath.hashCode ^
        locationEntity.hashCode ^
        (ipAddress?.hashCode ?? 0) ^
        speakerSKU.hashCode ^
        type.hashCode ^
        zAxis.hashCode;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'rotation': rotation,
      'gain': gain,
      'assetImagePath': assetImagePath,
      'componentType': 'speaker',
      'type': type.name,
      'locationEntity': locationEntity.toJson(),
      'ipAddress': ipAddress,
      'speakerSKU': speakerSKU,
      'price': price,
      "zAxis": zAxis,
      'hardwareName': hardwareName,
      'pitch': pitch,
      'roll': roll,
      'yaw': yaw,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
    };
  }

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String?,
      name: json['name'] as String,
      pos: Offset(json['pos']['dx'] as double, json['pos']['dy'] as double),
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      rotation: (json['rotation'] as num).toDouble(),
      gain: (json['gain'] as num).toDouble(),
      assetImagePath: json['assetImagePath'] as String,
      type: OutputType.values.firstWhere((OutputType e) => e.name == json['type'], orElse: () => OutputType.analogOutput),
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      ipAddress: json['ipAddress'] as String?,
      speakerSKU: json['speakerSKU'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? '',
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      roll: (json['roll'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }
}

extension SpeakerExtension on Speaker {
  Speaker getClone() {
    final json = toJson();
    json['id'] = FusionUtils.shortStringUUID();
    return Speaker.fromJson(json);
  }
}
