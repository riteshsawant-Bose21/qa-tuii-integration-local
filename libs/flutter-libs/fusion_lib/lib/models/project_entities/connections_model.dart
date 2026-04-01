import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

enum ConnectionType { analog, aes67, ethernet, usb, wifi, bluetooth, hdmi, audioJack, rca, amplifier, dspAnalog, endpoint, xlr, circuit, gpio, speaker, dsp }

/// Represents a wiring connection between two devices and their ports.
class WiringConnectionModel {
  final String id;
  final String deviceId;
  final String portId;
  final String targetDeviceId;
  final String targetPortId;
  final ConnectionType type; // e.g. signal, power, data

  final List<FusionCanvasPoint>? points; // For visual representation of the connection on the canvas

  WiringConnectionModel({
    String? id,
    required this.deviceId,
    required this.portId,
    required this.targetDeviceId,
    required this.targetPortId,
    required this.type,
    this.points,
  }) : id = id ?? "WIRE${FusionUtils.shortStringUUID()}";

  WiringConnectionModel copyWith({
    String? deviceId,
    String? portId,
    String? targetDeviceId,
    String? targetPortId,
    ConnectionType? type,
    List<FusionCanvasPoint>? points,
  }) {
    return WiringConnectionModel(
      id: id,
      deviceId: deviceId ?? this.deviceId,
      portId: portId ?? this.portId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetPortId: targetPortId ?? this.targetPortId,
      type: type ?? this.type,
      points: points ?? this.points,
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
      points: (json['points'] as List<dynamic>?)?.map((point) => FusionCanvasPoint.fromMap(point as Map<String, dynamic>)).toList(),
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
      'points': points?.map((point) => point.toMap()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
