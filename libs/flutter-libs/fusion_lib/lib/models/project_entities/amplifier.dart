import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:uuid/uuid.dart';

class Amplifier extends HardwareComponent {
  final int channels;
  final double powerPerChannel;
  final MaterialColor color;
  final String sku;

  Amplifier({
    String? id,
    required super.name,
    required this.channels,
    required this.powerPerChannel,
    required this.color,
    super.assetImagePath = 'assets/images/amplifier.png',
    super.price = 1000.0,
    super.pos,
    super.wiringPos,
    super.zAxis,
    String? hardwareName,
    LocationModel? locationEntity,
    super.lockListeningArea,
    super.communicationPorts,
    super.portData,
    super.inputPortsData,
    super.outputPortsData,
    this.sku = '',
  }) : super(
         hardwareName: hardwareName ?? name,
         locationEntity: locationEntity ?? LocationModel(),
         id: id ?? "AMPLIFIER${FusionUtils.shortStringUUID()}",
       );

  double get totalPower => channels * powerPerChannel;

  //copyWith
  @override
  Amplifier copyWith({
    String? name,
    int? channels,
    double? powerPerChannel,
    MaterialColor? color,
    String? assetImagePath,
    double? price,
    String? hardwareName,
    LocationModel? locationEntity,
    Offset? pos,
    Offset? wiringPos,
    double? zAxis,
    String? id,
    bool? lockListeningArea,
    List<PortData>? communicationPorts,
    List<PortData>? inputPortsData,
    List<PortData>? outputPortsData,
    String? sku,
  }) {
    return Amplifier(
      name: name ?? this.name,
      channels: channels ?? this.channels,
      powerPerChannel: powerPerChannel ?? this.powerPerChannel,
      color: color ?? this.color,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      price: price ?? this.price,
      hardwareName: hardwareName ?? this.hardwareName,
      locationEntity: locationEntity ?? this.locationEntity,
      pos: pos ?? this.pos,
      wiringPos: wiringPos ?? this.wiringPos,
      zAxis: zAxis ?? this.zAxis,
      id: id ?? this.id,
      lockListeningArea: lockListeningArea ?? this.lockListeningArea,
      communicationPorts: communicationPorts ?? this.communicationPorts,
      inputPortsData: inputPortsData ?? this.inputPortsData,
      outputPortsData: outputPortsData ?? this.outputPortsData,
      sku: sku ?? this.sku,
    );
  }

  factory Amplifier.fromJson(Map<String, dynamic> json) {
    return Amplifier(
      name: json['name'] as String,
      channels: json['channels'] as int,
      powerPerChannel: (json['powerPerChannel'] as num).toDouble(),
      color: _materialColorFromHex(json['color'] as String),
      assetImagePath: json['assetImagePath'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      id: json['id'] as String?,
      hardwareName: json['hardwareName'] as String?,
      locationEntity: json['locationEntity'] != null ? LocationModel.fromJson(json['locationEntity'] as Map<String, dynamic>) : null,
      pos: json['pos'] != null ? Offset((json['pos']['dx'] as num).toDouble(), (json['pos']['dy'] as num).toDouble()) : null,
      wiringPos: json['wiringPos'] != null ? Offset((json['wiringPos']['dx'] as num).toDouble(), (json['wiringPos']['dy'] as num).toDouble()) : null,
      zAxis: (json['zAxis'] as num?)?.toDouble() ?? 0.0,
      lockListeningArea: json['lockListeningArea'] as bool? ?? false,
      communicationPorts:
          (json['communicationPorts'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      outputPortsData: (json['outputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      inputPortsData: (json['inputPortsData'] as List<dynamic>?)?.map((dynamic e) => PortData.fromJson(e as Map<String, dynamic>)).toList() ?? <PortData>[],
      sku: json['sku'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'channels': channels,
      'powerPerChannel': powerPerChannel,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
      'assetImagePath': assetImagePath,
      'price': price,
      'id': id,
      'hardwareName': hardwareName,
      'locationEntity': locationEntity.toJson(),
      'pos': <String, double>{'dx': pos.dx, 'dy': pos.dy},
      'wiringPos': wiringPos != null ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy} : null,
      'zAxis': zAxis,
      'componentType': 'amplifier',
      'lockListeningArea': lockListeningArea,
      'communicationPorts': communicationPorts.map((PortData port) => port.toJson()).toList(),
      'outputPortsData': outputPortsData.map((PortData port) => port.toJson()).toList(),
      'inputPortsData': inputPortsData.map((PortData port) => port.toJson()).toList(),
      'sku': sku,
    };
  }

  /// Helper to convert hex string to MaterialColor
  static MaterialColor _materialColorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // add full opacity if alpha missing
    }
    final int colorInt = int.parse(hex, radix: 16);
    final Color baseColor = Color(colorInt);

    // Generate MaterialColor from single Color
    return MaterialColor(baseColor.value, <int, Color>{
      50: baseColor.withOpacity(.1),
      100: baseColor.withOpacity(.2),
      200: baseColor.withOpacity(.3),
      300: baseColor.withOpacity(.4),
      400: baseColor.withOpacity(.5),
      500: baseColor.withOpacity(.6),
      600: baseColor.withOpacity(.7),
      700: baseColor.withOpacity(.8),
      800: baseColor.withOpacity(.9),
      900: baseColor.withOpacity(1),
    });
  }
}
