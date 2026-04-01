import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

enum SourceType { mic, media, generic, paging }

enum PagingSourceType { messagePlayer, messagePlayerWithZoneSelect, pagingMic, pagingMicWithZoneSelect }

enum SourceConnectionType {
  analogInput("Wired"),
  aes67input("Aes67"),
  bluetooth("Bluetooth"),
  usb("USB"),
  audioJack("Audio Jack"),
  rca("RCA"),
  xlr("XLR"),
  hdmi("HDMI");

  const SourceConnectionType(this.displayName);

  final String displayName;
}

extension SourceConnectionTypeExtension on SourceConnectionType {
  String get connectionType {
    switch (this) {
      case SourceConnectionType.analogInput:
        return 'analog';
      case SourceConnectionType.aes67input:
        return 'aes67';
      case SourceConnectionType.bluetooth:
        return 'analog';
      case SourceConnectionType.usb:
        return 'analog';
      case SourceConnectionType.audioJack:
        return 'analog';
      case SourceConnectionType.rca:
        return 'analog';
      case SourceConnectionType.xlr:
        return 'analog';
      case SourceConnectionType.hdmi:
        return 'analog';
    }
  }
}

class Source extends HardwareComponent {
  /// Type of the source
  final SourceType type;
  final SourceConnectionType connectionType;
  String? ipAddress; //for AES67 sources
  final String sku;
  final PagingSourceType? pagingSourceType; // Only applicable for paging sources

  /// Constructor for SourceEntity
  Source({
    String? id,
    required super.locationEntity,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required this.type,
    required this.connectionType,
    required super.assetImagePath,
    this.ipAddress,
    List<int>? portNumbers,
    required this.sku,
    required super.price,
    super.lockListeningArea,
    String? hardwareName,
    super.portData,
    super.equipmentLocationPosition,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
    required super.addedFromBuildingPage,
    this.pagingSourceType,
  }) : super(
         hardwareName: hardwareName ?? name,
         id: id ?? "SOURCE${FusionUtils.shortStringUUID()}",
       );

  @override
  Source copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    SourceType? type,
    SourceConnectionType? connectionType,
    String? assetImagePath,
    LocationModel? locationEntity,
    String? ipAddress,
    String? sku,
    double? price,
    String? hardwareName,
    bool? lockListeningArea,
    int? equipmentLocationPosition,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    bool? addedFromBuildingPage,
    PagingSourceType? pagingSourceType,
  }) {
    return Source(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      type: type ?? this.type,
      connectionType: connectionType ?? this.connectionType,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      ipAddress: ipAddress ?? this.ipAddress,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
      addedFromBuildingPage: addedFromBuildingPage ?? this.addedFromBuildingPage,
      equipmentLocationPosition: equipmentLocationPosition ?? this.equipmentLocationPosition,
      pagingSourceType: pagingSourceType ?? this.pagingSourceType,
    );
  }

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
      type: SourceType.values.firstWhere(
        (SourceType e) => e.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => SourceType.generic, //throw FormatException('Unknown SourceType in JSON: ${json['type']}'),
      ),
      connectionType: SourceConnectionType.values.firstWhere(
        (SourceConnectionType e) => e.name.toLowerCase() == (json['connectionType'] as String?)?.toLowerCase(),
        orElse: () => SourceConnectionType.values.firstWhere(
          (e) => e.name == json['type'],
        ), //throw FormatException('Unknown SourceConnectionType in JSON: ${json['connectionType']}'),
      ),
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      ipAddress: json['ipAddress'] as String?,
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? '',
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      addedFromBuildingPage: json['addedFromBuildingPage'] as bool? ?? false,
      equipmentLocationPosition: DeserializationUtil.intDeserializer.deserialize(json['equipmentLocationPosition']),
      pagingSourceType: json['pagingSourceType'] != null
          ? PagingSourceType.values.firstWhere(
              (PagingSourceType e) => e.name == json['pagingSourceType'],
              orElse: () => PagingSourceType.messagePlayer,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': pos != null ? <String, double>{'dx': pos!.dx, 'dy': pos!.dy} : null,
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'type': type.name,
      'connectionType': connectionType.name,
      'assetImagePath': assetImagePath,
      'componentType': 'source',
      'locationEntity': locationEntity.toJson(),
      'ipAddress': ipAddress,
      'sku': sku,
      'price': price,
      'hardwareName': hardwareName,
      'zAxis': zAxis,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
      'addedFromBuildingPage': addedFromBuildingPage,
      'equipmentLocationPosition': equipmentLocationPosition,
      'pagingSourceType': pagingSourceType?.name,
    };
  }
}
