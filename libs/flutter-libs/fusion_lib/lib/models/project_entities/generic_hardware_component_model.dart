import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

enum GenericHardwareComponentType { rack, other }

class GenericHardwareComponent extends HardwareComponent {
  GenericHardwareComponentType type;
  final String sku;

  GenericHardwareComponent({
    super.id,
    required super.locationEntity,
    required super.name,
    super.zAxis,
    required Offset super.pos,
    super.wiringPos,
    required this.type,
    required super.assetImagePath,
    required super.price,
    super.portData,
    super.communicationPorts,
    super.inputPortsData,
    super.outputPortsData,
    String? sku,
    String? hardwareName,
    super.lockListeningArea,
  }) : sku = sku ?? name,
       super(hardwareName: hardwareName ?? name);

  @override
  GenericHardwareComponent copyWith({
    String? id,
    String? name,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    GenericHardwareComponentType? type,
    String? assetImagePath,
    LocationModel? locationEntity,
    double? price,
    String? hardwareName,
    String? sku,
    int? outputPorts,
    int? inputPorts,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
  }) {
    return GenericHardwareComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      type: type ?? this.type,
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
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'type': type.name,
      "zAxis": zAxis,
      'assetImagePath': assetImagePath,
      'componentType': 'generic',
      'locationEntity': locationEntity.toJson(),
      'price': price,
      'hardwareName': hardwareName,
      'sku': sku,
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
    };
  }

  factory GenericHardwareComponent.fromJson(Map<String, dynamic> json) {
    final String rawType = (json['type'] as String? ?? '').toLowerCase();

    final GenericHardwareComponentType productType = GenericHardwareComponentType.values.firstWhere(
      (GenericHardwareComponentType e) => e.name.toLowerCase() == rawType,
      orElse: () {
        throw FormatException('Unknown CanvasProductType "$rawType" in JSON: $json');
      },
    );

    final Map<String, dynamic> posMap = json['pos'] as Map<String, dynamic>? ?? (throw FormatException('Missing "pos" in CanvasProduct JSON: $json'));

    final double dx = (posMap['dx'] as num?)?.toDouble() ?? (throw FormatException('Invalid pos.dx in CanvasProduct JSON: $json'));
    final double dy = (posMap['dy'] as num?)?.toDouble() ?? (throw FormatException('Invalid pos.dy in CanvasProduct JSON: $json'));

    return GenericHardwareComponent(
      id: json['id'] as String?,
      name: json['name'] as String? ?? (throw FormatException('Missing "name" in CanvasProduct JSON: $json')),
      pos: Offset(dx, dy),
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['x'] as num).toDouble(), (json['wiringPos']['y'] as num).toDouble()) : null,
      type: productType,
      assetImagePath: json['assetImagePath'] as String,
      locationEntity: LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hardwareName: json['hardwareName'],
      sku: json['sku'] as String? ?? '',
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
    );
  }
}
