import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

enum ConnectionType {
  analog("io_in_analog"),
  aes67("io_in_aes67"),
  aes67Out("io_out_aes67"),
  ethernet("io_in_aes67"),
  usb("io_in_usb"),
  wifi("io_in_wifi"),
  bluetooth("io_in_bluetooth"),
  hdmi("io_in_hdmi"),
  audioJack("io_in_analog"),
  rca("io_in_analog"),
  amplifier("io_out_analog"),
  dspAnalog("io_in_analog"),
  endpoint("io_in_analog"),
  xlr("io_in_analog"),
  circuit("io_out_analog"),
  gpio("io_in_gpio"),
  speaker("io_out_analog"),
  dsp("io_in_analog");

  const ConnectionType(this.type);
  final String type;
}

/// Represents a wiring connection between two devices and their ports.
class WiringConnectionModel {
  final String id;
  final String deviceId;
  final String portId;
  final String targetDeviceId;
  final String targetPortId;
  final ConnectionType type; // e.g. signal, power, data

  WiringConnectionModel({
    String? id,
    required this.deviceId,
    required this.portId,
    required this.targetDeviceId,
    required this.targetPortId,
    required this.type,
  }) : id = id ?? "WIRE${FusionUtils.shortStringUUID()}";

  WiringConnectionModel copyWith({
    String? deviceId,
    String? portId,
    String? targetDeviceId,
    String? targetPortId,
    ConnectionType? type,
  }) {
    return WiringConnectionModel(
      deviceId: deviceId ?? this.deviceId,
      portId: portId ?? this.portId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetPortId: targetPortId ?? this.targetPortId,
      type: type ?? this.type,
    );
  }

  factory WiringConnectionModel.fromJson(Map<String, dynamic> json) {
    return WiringConnectionModel(
      id: json['id'],
      deviceId: json['deviceId'] ?? '',
      portId: json['portId'] ?? '',
      targetDeviceId: json['targetDeviceId'] ?? '',
      targetPortId: json['targetPortId'] ?? '',
      type: ConnectionType.values.firstWhere((e) => e.name == json['type'], orElse: () => ConnectionType.dsp),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'portId': portId,
      'targetDeviceId': targetDeviceId,
      'targetPortId': targetPortId,
      'type': type.name,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
