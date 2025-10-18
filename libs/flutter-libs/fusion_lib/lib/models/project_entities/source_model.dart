import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

enum SourceType { analogInput, aes67input, bluetooth }

class Source extends HardwareComponent {
  /// Type of the source
  final SourceType type;
  String? ipAddress; //for AES67 sources
  final List<int> portNumbers;
  final String? fusionDeviceId;
  final String sku;

  /// Constructor for SourceEntity
  Source({
    String? id,
    required super.locationEntity,
    required super.name,
    super.pos,
    super.wiringPos,
    super.zAxis,
    required this.type,
    required super.assetImagePath,
    this.ipAddress,
    List<int>? portNumbers,
    this.fusionDeviceId,
    required this.sku,
    required super.price,
    super.lockListeningArea,
    String? hardwareName,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
  }) : portNumbers = portNumbers ?? <int>[],
       super(hardwareName: hardwareName ?? name, id: id ?? "SOURCE${FusionUtils.shortStringUUID()}");

  @override
  Source copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    SourceType? type,
    String? assetImagePath,
    LocationModel? locationEntity,
    String? ipAddress,
    List<int>? portNumbers,
    String? fusionDeviceId,
    String? sku,
    double? price,
    String? hardwareName,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return Source(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      type: type ?? this.type,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      ipAddress: ipAddress ?? this.ipAddress,
      portNumbers: portNumbers ?? this.portNumbers,
      fusionDeviceId: fusionDeviceId ?? this.fusionDeviceId,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
    );
  }

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: Offset(json['pos']['dx'] as double, json['pos']['dy'] as double),
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      type: SourceType.values.firstWhere(
        (SourceType e) => e.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => throw FormatException('Unknown SourceType in JSON: ${json['type']}'),
      ),
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      ipAddress: json['ipAddress'] as String?,
      portNumbers: (json['portNumbers'] as List<dynamic>?)?.map((dynamic e) => e as int).toList() ?? <int>[],
      fusionDeviceId: json["fusionDeviceId"] as String?,
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'] as String? ?? '',
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'type': type.name,
      'assetImagePath': assetImagePath,
      'componentType': 'source',
      'locationEntity': locationEntity.toJson(),
      'ipAddress': ipAddress,
      'portNumbers': portNumbers,
      'fusionDeviceId': fusionDeviceId,
      'sku': sku,
      'price': price,
      'hardwareName': hardwareName,
      'zAxis': zAxis,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
    };
  }
}
