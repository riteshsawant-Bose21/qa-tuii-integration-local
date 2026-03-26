import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

enum ConnectionType { 
  analog,
  aes67,
  ethernet,
  usb,
  wifi,
  bluetooth,
  hdmi,
  audioJack,
  amplifier,
  dspAnalog,
  endpoint,
  xlr,
  circuit,
  gpio,
  dsp
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
