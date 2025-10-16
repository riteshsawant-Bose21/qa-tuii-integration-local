import 'package:fusion_lib/fusion_lib.dart';

/// Enum for port placement
enum PortPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  footerLeft,
  footerRight,
  footerCenter,
}

enum PortType {
  analogInput,
  analogOutput,
  ethernet,
  usb,
  serial,
  ble,
  wifi,
  hdmi,
  audioJack,
  amplifierInput,
  amplifierOutput,
  dspAnalogInput,
  dspAnalogOutput,
  controllerInput,
  controllerOutput,
  sourceData,
  speakerData,
  digitalInput,
  digitalOutput,
}

//DSP input port supported device port types
//analogInput,

/// Communication Port Model
class PortData {
  final String id;
  final String name; // "Ethernet", "USB"
  final String? description;
  final PortType type;
  final List<PortType> compatibleTypes;

  /// Layout info
  final PortPosition position;
  final int portNumber; // render order in that position group

  PortData({
    String? id,
    required this.name,
    this.description,
    required this.position,
    required this.portNumber,
    required this.type,
    required this.compatibleTypes,
  }) : id = id ?? FusionUtils.shortStringUUID();

  //from json
  factory PortData.fromJson(Map<String, dynamic> json) {
    return PortData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      position: PortPosition.values.firstWhere((e) => e.name == json['position']),
      portNumber: json['portNumber'] as int,
      type: PortType.values.firstWhere((e) => e.name == json['type']),
      compatibleTypes: (json['compatibleTypes'] as List<dynamic>).map((e) => PortType.values.firstWhere((pt) => pt.name == e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'position': position.name,
      'portNumber': portNumber,
      'type': type.name,
      'compatibleTypes': compatibleTypes.map((e) => e.name).toList(),
    };
  }
}
