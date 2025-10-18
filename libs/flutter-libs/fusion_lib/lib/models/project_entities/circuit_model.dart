import 'package:fusion_lib/fusion_lib.dart';

class CircuitModel {
  final String id;
  final String name;
  PortData inputPort;

  CircuitModel({
    String? id,
    required this.name,
    PortData? inputPort,
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
    String? zoneId,
    PortData? inputPort,
  }) {
    return CircuitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inputPort: inputPort ?? this.inputPort,
    );
  }

  factory CircuitModel.fromJson(Map<String, dynamic> json) {
    return CircuitModel(
      id: json['id'],
      name: json['name'],
      inputPort: json['inputPort'] != null ? PortData.fromJson(json['inputPort']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inputPort': inputPort.toJson(),
    };
  }
}
