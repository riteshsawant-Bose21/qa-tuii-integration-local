import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

enum FusionDeviceSetupStatus {
  completed,
  notStarted,
}

class FusionDsp extends HardwareComponent {
  final String location;
  final String? localIp;
  final String? cloudId;
  final bool isClaimed;
  final FusionDeviceSetupStatus status;
  final String sku;

  FusionDsp({
    String? id,
    required super.name,
    required this.location,
    required this.status,
    this.localIp,
    super.price = 1000,
    this.cloudId,
    this.isClaimed = false,
    super.lockListeningArea,
    super.pos,
    super.wiringPos,
    super.zAxis,
    String? hardwareName,
    super.assetImagePath = 'assets/images/fusion_device.png',
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
    required super.locationEntity,
    this.sku = '',
  }) : super(hardwareName: hardwareName ?? name);

  @override
  String toString() {
    return 'FusionDevice{id: $id, name: $name, location: $location, status: $status, localIp: $localIp, cloudId: $cloudId, isClaimed: $isClaimed}';
  }

  //copy with
  @override
  FusionDsp copyWith({
    String? id,
    String? name,
    String? location,
    FusionDeviceSetupStatus? status,
    String? localIp,
    String? cloudId,
    bool? isClaimed,
    String? hardwareName,
    double? price,
    String? assetImagePath,
    LocationModel? locationEntity,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    String? sku,
  }) {
    return FusionDsp(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      localIp: localIp ?? this.localIp,
      cloudId: cloudId ?? this.cloudId,
      isClaimed: isClaimed ?? this.isClaimed,
      hardwareName: hardwareName ?? this.hardwareName,
      price: price ?? this.price,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      locationEntity: locationEntity ?? this.locationEntity,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
      sku: sku ?? this.sku,
    );
  }

  //from json
  factory FusionDsp.fromJson(Map<String, dynamic> json) {
    return FusionDsp(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      status: FusionDeviceSetupStatus.values.firstWhere(
        (FusionDeviceSetupStatus e) => e.name == json['status'],
        orElse: () => FusionDeviceSetupStatus.notStarted,
      ),
      localIp: json['address'] as String?,
      cloudId: json['xyte_cloud_id'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? false,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 1000,
      hardwareName: json['hardwareName'] as String?,
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json[' pos']['dy'] as num).toDouble()) : const Offset(0, 0),
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
      assetImagePath: json['assetImagePath'] as String? ?? '',
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      sku: json['sku'] as String? ?? '',
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'status': status.name,
      'location': location,
      'address': localIp,
      'xyte_cloud_id': cloudId,
      'is_claimed': isClaimed,
      'componentType': 'fusionDsp',
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'assetImagePath': assetImagePath,
      "zAxis": zAxis,
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
      'sku': sku,
    };
  }
}
