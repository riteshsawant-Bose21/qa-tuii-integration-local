import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class FusionEndpoints extends HardwareComponent {
  final String ipAddress;
  final String sku;

  FusionEndpoints({
    String? id,
    required super.name,
    required this.ipAddress,
    required this.sku,
    required super.assetImagePath,
    super.price = 0,
    super.pos,
    super.wiringPos,
    super.zAxis,
    String? hardwareName,
    LocationModel? locationEntity,
    super.lockListeningArea,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
  }) : super(
         hardwareName: hardwareName ?? name,
         locationEntity: locationEntity ?? LocationModel(),
         id: id ?? "ENDPOINT${FusionUtils.shortStringUUID()}",
       );

  @override
  FusionEndpoints copyWith({
    String? id,
    String? name,
    String? ipAddress,
    String? sku,
    List<int>? portNumbers,
    String? assetImagePath,
    double? price,
    String? hardwareName,
    LocationModel? locationEntity,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return FusionEndpoints(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      sku: sku ?? this.sku,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      locationEntity: locationEntity ?? this.locationEntity,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'sku': sku,
      'assetImagePath': assetImagePath,
      'price': price,
      'hardwareName': hardwareName,
      'locationEntity': locationEntity.toJson(),
      'pos': pos != null ? <String, double>{'dx': pos!.dx, 'dy': pos!.dy} : null,
      'wiringPos': wiringPos != null ? {'x': wiringPos!.dx, 'y': wiringPos!.dy} : null,
      'zAxis': zAxis,
      'componentType': 'fusionEndpoint',
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
    };
  }

  //from json
  factory FusionEndpoints.fromJson(Map<String, dynamic> json) {
    return FusionEndpoints(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      sku: json['sku'] as String,
      assetImagePath: json['assetImagePath'] as String,
      price: (json['price'] as num).toDouble(),
      hardwareName: json['hardwareName'] as String?,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      zAxis: (json['zAxis'] as num).toDouble(),
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }
}
