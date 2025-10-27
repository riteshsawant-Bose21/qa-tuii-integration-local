import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class CircuitModel {
  final String id;
  final String name;
  final PortData inputPort;
  final String? tapSetting;
  final String? impedance;
  final Offset? wiringPos;

  CircuitModel({
    String? id,
    required this.name,
    PortData? inputPort,
    this.impedance,
    this.tapSetting,
    this.wiringPos,
  }) : id = id ?? "CIRCUIT${FusionUtils.shortStringUUID()}",
       inputPort =
           inputPort ??
           PortData(
             name: "1",
             position: PortPosition.topLeft,
             description: PortType.circuitInput.description,
             portNumber: 1,
             compatibleTypes: [
               PortType.amplifierOutput,
             ],
             type: PortType.circuitInput,
           );

  //copy with
  CircuitModel copyWith({
    String? id,
    String? name,
    PortData? inputPort,
    String? tapSetting,
    String? impedance,
    Offset? wiringPos,
  }) {
    return CircuitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inputPort: inputPort ?? this.inputPort,
      tapSetting: tapSetting ?? this.tapSetting,
      impedance: impedance ?? this.impedance,
      wiringPos: wiringPos ?? this.wiringPos,
    );
  }

  factory CircuitModel.fromJson(Map<String, dynamic> json) {
    return CircuitModel(
      id: json['id'],
      name: json['name'],
      inputPort: json['inputPort'] != null
          ? PortData.fromJson(json['inputPort'])
          : null,
      impedance: json['impedance'],
      tapSetting: json['tapSetting'],
      wiringPos: json['wiringPos'] != null
          ? Offset(
              (json['wiringPos']['dx'] as num).toDouble(),
              (json['wiringPos']['dy'] as num).toDouble(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inputPort': inputPort.toJson(),
      'impedance': impedance,
      'tapSetting': tapSetting,
      'wiringPos': wiringPos != null
          ? <String, double>{'dx': wiringPos!.dx, 'dy': wiringPos!.dy}
          : null,
    };
  }
}
