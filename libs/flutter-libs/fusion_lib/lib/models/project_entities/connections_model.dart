// ignore_for_file: public_member_api_docs, sort_constructors_first
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
  final List<AxisLock> axisLocks; // Optional list of axis locks for this connection

  WiringConnectionModel({
    String? id,
    required this.deviceId,
    required this.portId,
    required this.targetDeviceId,
    required this.targetPortId,
    required this.type,
    this.axisLocks = const [],
  }) : id = id ?? "WIRE${FusionUtils.shortStringUUID()}";

  WiringConnectionModel copyWith({
    String? deviceId,
    String? portId,
    String? targetDeviceId,
    String? targetPortId,
    ConnectionType? type,
    List<AxisLock>? axisLocks,
  }) {
    return WiringConnectionModel(
      id: id,
      deviceId: deviceId ?? this.deviceId,
      portId: portId ?? this.portId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetPortId: targetPortId ?? this.targetPortId,
      type: type ?? this.type,
      axisLocks: axisLocks ?? this.axisLocks,
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
      axisLocks: (json['axisLocks'] as List<dynamic>?)?.map((e) => AxisLock(x: e['x'], y: e['y'])).toList() ?? [],
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
      'axisLocks': axisLocks.map((e) => {'x': e.x, 'y': e.y}).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class AxisLock {
  /// Either x Or y will be non null. Only one of the axis will be non null, other one will be null.
  ///  This indicates which axis is locked for this connection.
  final double? x;
  final double? y;

  AxisLock({this.x, this.y});

  AxisLock copyWith({
    double? x,
    double? y,
  }) {
    return AxisLock(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  bool operator ==(covariant AxisLock other) {
    if (identical(this, other)) return true;

    return other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'AxisLock(x: $x, y: $y)';
}
