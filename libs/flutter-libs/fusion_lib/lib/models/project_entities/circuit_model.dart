import 'package:fusion_lib/fusion_lib.dart';

class CircuitModel {
  final String id;
  final String name;
  final PortData inputPort;
  final String? tapSetting;
  final String? impedance;

  CircuitModel({
    String? id,
    required this.name,
    PortData? inputPort,
    this.impedance,
    this.tapSetting,
  }) : id = id ?? "CIRCUIT${FusionUtils.shortStringUUID()}",
       inputPort =
           inputPort ??
           PortData(
             name: "cirInput",
             position: PortPosition.topLeft,
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
  }) {
    return CircuitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inputPort: inputPort ?? this.inputPort,
      tapSetting: tapSetting ?? this.tapSetting,
      impedance: impedance ?? this.impedance,
    );
  }

  factory CircuitModel.fromJson(Map<String, dynamic> json) {
    return CircuitModel(
      id: json['id'],
      name: json['name'],
      inputPort: json['inputPort'] != null ? PortData.fromJson(json['inputPort']) : null,
      impedance: json['impedance'],
      tapSetting: json['tapSetting'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inputPort': inputPort.toJson(),
      'impedance': impedance,
      'tapSetting': tapSetting,
    };
  }
}
