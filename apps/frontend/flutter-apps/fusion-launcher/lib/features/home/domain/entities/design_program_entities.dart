import 'dart:convert';

import 'package:flutter/material.dart';

enum MountType { wall, ceiling }

class Floor {
  final int id;
  final List<Room> rooms;
  final List<FusionDevice> devices;

  Map<String, dynamic> exportAllToMap(List<Floor> floors) {
    return <String, dynamic>{
      'floors': floors.map<Map<String, dynamic>>((Floor f) => f.toJson()).toList(),
    };
  }

  /// Returns a JSON string (indented) for the entire structure.
  String exportAllToJson(List<Floor> floors) {
    final Map<String, dynamic> data = exportAllToMap(floors);
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Floor({
    required this.id,
    required this.rooms,
    this.devices = const <FusionDevice>[],
  });

  //copy with to add new device
  Floor copyWith({
    int? id,
    List<Room>? rooms,
    List<FusionDevice>? devices,
  }) {
    return Floor(
      id: id ?? this.id,
      rooms: rooms ?? this.rooms,
      devices: devices ?? this.devices,
    );
  }

  //from json
  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['floorId'] as int,
      rooms: (json['rooms'] as List<dynamic>).map((dynamic e) => Room.fromJson(e as Map<String, dynamic>)).toList(),
      devices: (json['devices'] as List<dynamic>).map((dynamic e) => FusionDevice.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'floorId': id,
        'rooms': rooms.map((Room r) => r.toJson()).toList(),
        'devices': devices.map((FusionDevice d) => d.toJson()).toList(),
      };
}

class Room {
  int id;
  Rect base;

  Room({required this.id, required this.base});

  Rect scaled(double wf, double hf) => Rect.fromLTWH(
        base.left * wf,
        base.top * hf,
        base.width * wf,
        base.height * hf,
      );

  //from json
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['roomId'] as int,
      base: Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roomId': id,
        'x': base.left,
        'y': base.top,
        'width': base.width,
        'height': base.height,
      };
}

/// Types of devices that can be placed
enum FusionDeviceType { speaker, mic, analogInput, musicPlayer, other }

/// Unified model representing a device, compatible with both pages
class FusionDevice {
  Offset rel;
  final int roomId;
  final FusionDeviceType type;
  final MountType? mount;
  bool selected = false;
  String name;

  FusionDevice({
    required this.rel,
    required this.roomId,
    required this.type,
    this.mount,
    this.name = '',
  });

  Offset scaledPosition(Size size) => Offset(rel.dx * size.width, rel.dy * size.height);

  /// Convert device from JSON (supports previous page schema)
  factory FusionDevice.fromJson(Map<String, dynamic> json) {
    // relX, relY
    final double dx = (json['relX'] as num).toDouble();
    final double dy = (json['relY'] as num).toDouble();
    // type or assume speaker for previous
    FusionDeviceType type;
    if (json.containsKey('type')) {
      type = FusionDeviceType.values.firstWhere((FusionDeviceType e) => e.toString().split('.').last == json['type'], orElse: () => FusionDeviceType.other);
    } else {
      type = FusionDeviceType.speaker;
    }
    // mount if present
    MountType? mount;
    if (json.containsKey('mount')) {
      mount = MountType.values.firstWhere((MountType m) => m.toString().split('.').last == json['mount'], orElse: () => MountType.wall);
    }
    // name
    final String name = json['deviceName'] as String? ?? '';
    // roomId may be under 'room_id' or previous format
    final int roomId = json['room_id'] is int
        ? json['room_id'] as int
        : json['roomId'] is int
            ? json['roomId'] as int
            : 0;

    return FusionDevice(
      rel: Offset(dx, dy),
      roomId: roomId,
      type: type,
      mount: mount,
      name: name,
    );
  }

  /// Serialize to JSON (includes both type and mount)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{
      'deviceName': name,
      'type': type.toString().split('.').last,
      'relX': rel.dx,
      'relY': rel.dy,
    };
    if (mount != null) {
      map['mount'] = mount.toString().split('.').last;
    }
    return map;
  }
}
