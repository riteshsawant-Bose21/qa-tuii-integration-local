import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class HardwareRack extends HardwareComponent {
  HardwareRack({
    String? id,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required super.assetImagePath,
    required super.locationEntity,
    required super.price,
    String? hardwareName,
    super.lockListeningArea,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
  }) : super(
         id: id ?? "RACK${FusionUtils.shortStringUUID()}",
         hardwareName: hardwareName ?? name,
       );

  @override
  HardwareComponent copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return HardwareRack(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
    );
  }

  // JSON serialization

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
    'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
    'zAxis': zAxis,
    'assetImagePath': assetImagePath,
    'locationEntity': locationEntity.toJson(),
    'price': price,
    'componentType': 'hardwareRack',
    'hardwareName': hardwareName,
    'lockListeningArea': lockListeningArea,
    'communicationPorts': communicationPorts.map((e) => e.toJson()).toList(),
    'inputPortsData': inputPortsData.map((e) => e.toJson()).toList(),
    'outputPortsData': outputPortsData.map((e) => e.toJson()).toList(),
  };

  factory HardwareRack.fromJson(Map<String, dynamic> json) {
    return HardwareRack(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: Offset(json['pos']['dx'] as double, json['pos']['dy'] as double),
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
      zAxis: (json['zAxis'] as num).toDouble(),
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num).toDouble(),
      hardwareName: json['hardwareName'] as String,
      lockListeningArea: json['lockListeningArea'] as bool,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }
}
