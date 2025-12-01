import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class FusionController extends HardwareComponent {
  final String sku;

  FusionController({
    String? id,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required super.assetImagePath,
    LocationModel? locationEntity,
    required super.price,
    String? hardwareName,
    String? sku,
    super.lockListeningArea,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
  }) : sku = sku ?? name,
       super(
         hardwareName: hardwareName ?? name,
         locationEntity: locationEntity ?? LocationModel(),
         id: id ?? "CONTROLLER${FusionUtils.shortStringUUID()}",
       );

  @override
  FusionController copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    String? sku,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return FusionController(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      sku: sku ?? this.sku,
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
      'pos': pos != null ? <String, double>{'dx': pos!.dx, 'dy': pos!.dy} : null,
      'wiringPos': wiringPos != null ? {'x': wiringPos!.dx, 'y': wiringPos!.dy} : null,
      'zAxis': zAxis,
      'assetImagePath': assetImagePath,
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'sku': sku,
      'componentType': 'controller',
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
    };
  }

  factory FusionController.fromJson(Map<String, dynamic> json) {
    return FusionController(
      id: json['id'] as String?,
      name: json['name'] as String,
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? json['name'] as String,
      sku: json['sku'] as String? ?? json['name'] as String,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }
}
