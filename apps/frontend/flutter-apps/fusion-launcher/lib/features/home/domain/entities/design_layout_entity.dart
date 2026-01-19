import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'design_program_entities.dart';

/// Top-level model representing the entire layout data
class DesignLayoutEntity {
  final Size floorSize;
  final List<Floor> floors;
  final List<DeviceMapping> deviceMapping;

  DesignLayoutEntity({
    required this.floorSize,
    required this.floors,
    required this.deviceMapping,
  });

  factory DesignLayoutEntity.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> sizeJson = json['floorSize'] as Map<String, dynamic>;
    final Size floorSize = Size(
      (sizeJson['width'] as num).toDouble(),
      (sizeJson['height'] as num).toDouble(),
    );
    final List<Floor> floors = (json['floors'] as List<dynamic>).map<Floor>((dynamic f) => Floor.fromJson(f as Map<String, dynamic>)).toList();
    final List<DeviceMapping> mapping =
        (json['deviceMapping'] as List<dynamic>).map<DeviceMapping>((dynamic m) => DeviceMapping.fromJson(m as Map<String, dynamic>)).toList();
    return DesignLayoutEntity(
      floorSize: floorSize,
      floors: floors,
      deviceMapping: mapping,
    );
  }

  static DesignLayoutEntity initialDesignEntity() {
    const Size size = Size(910, 540);
    final Random rnd = Random();

    // define rooms
    final List<Room> floor1Rooms = <Room>[
      Room(id: 1, base: const Rect.fromLTWH(0, 0, 333, 200)),
      Room(id: 2, base: const Rect.fromLTWH(333, 0, 167, 200)),
      Room(id: 3, base: const Rect.fromLTWH(0, 200, 500, 200)),
    ];
    final List<Room> floor2Rooms = <Room>[
      Room(id: 1, base: const Rect.fromLTWH(0, 0, 500, 200)),
      Room(id: 2, base: const Rect.fromLTWH(0, 200, 500, 200)),
    ];

    /// Scatter [count] speakers randomly within [room].
    List<FusionDevice> makeSpeakers({
      required int count,
      required Room room,
    }) {
      return List<FusionDevice>.generate(count, (int i) {
        // random absolute position inside room rect
        final double absX = room.base.left + rnd.nextDouble() * room.base.width;
        final double absY = room.base.top + rnd.nextDouble() * room.base.height;
        // convert to relative coords (0–1) across full floor
        final double relX = absX / size.width;
        final double relY = absY / size.height;
        return FusionDevice(
          rel: Offset(relX, relY),
          roomId: room.id,
          type: FusionDeviceType.speaker,
          name: 'Speaker ${i + 1}',
        );
      });
    }

    return DesignLayoutEntity(
      floorSize: size,
      floors: <Floor>[
        Floor(
          id: 1,
          rooms: floor1Rooms,
          devices: makeSpeakers(count: 5, room: floor1Rooms[0]),
        ),
        Floor(
          id: 2,
          rooms: floor2Rooms,
          devices: makeSpeakers(count: 4, room: floor2Rooms[0]),
        ),
      ],
      deviceMapping: <DeviceMapping>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'floorSize': <String, double>{
          'width': floorSize.width,
          'height': floorSize.height,
        },
        'floors': floors.map((Floor f) => f.toJson()).toList(),
        'deviceMapping': deviceMapping.map((DeviceMapping m) => m.toJson()).toList(),
      };
}

/// Mapping entry for cross-floor device summary
class DeviceMapping {
  final String deviceName;
  final String floorName;
  final int floorId;
  final int roomId;
  final FusionDeviceType type;
  final MountType? mount;

  DeviceMapping({
    required this.deviceName,
    required this.floorName,
    required this.floorId,
    required this.roomId,
    required this.type,
    this.mount,
  });

  factory DeviceMapping.fromJson(Map<String, dynamic> json) {
    final FusionDeviceType type =
        FusionDeviceType.values.firstWhere((FusionDeviceType e) => e.toString().split('.').last == json['type'], orElse: () => FusionDeviceType.other);
    MountType? mount;
    if (json.containsKey('mount')) {
      mount = MountType.values.firstWhere((MountType m) => m.toString().split('.').last == json['mount'], orElse: () => MountType.wall);
    }
    return DeviceMapping(
      deviceName: json['deviceName'] as String,
      floorName: json['floor_name'] as String,
      floorId: json['floor_id'] as int,
      roomId: json['room_id'] as int,
      type: type,
      mount: mount,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, Object> map = <String, Object>{
      'deviceName': deviceName,
      'floor_name': floorName,
      'floor_id': floorId,
      'room_id': roomId,
      'type': type.toString().split('.').last,
    };
    if (mount != null) {
      map['mount'] = mount.toString().split('.').last;
    }
    return map;
  }
}
